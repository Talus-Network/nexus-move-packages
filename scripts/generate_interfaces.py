#!/usr/bin/env python3
"""Generate minimal Move interfaces from the private Nexus package graph."""

from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path
from typing import Any


PACKAGES = (
    ("kernel", "nexus_kernel"),
    ("primitives", "nexus_primitives"),
    ("interface", "nexus_interface"),
    ("tool", "nexus_tool"),
    ("registry", "nexus_registry"),
    ("workflow", "nexus_workflow"),
    ("scheduler", "nexus_scheduler"),
)
ROOT_PACKAGE = "scheduler"

# The published workflow package exposes additional public declarations so the
# Scheduler package can call across package boundaries. Those declarations are
# protocol implementation details: integrators cannot create the RuntimePermit
# required to call them. Keep this allowlist intentionally small and add an
# item only when it is part of the supported, directly composable API.
WORKFLOW_INTERFACE = {
    "execution": {
        "structs": frozenset({"DAGExecution"}),
        "enums": frozenset(),
        "functions": frozenset(
            {
                "has_vertex_authorization_grant",
                "assert_complete_authorization_bindings",
                "interface_version",
                "task_id",
                "occurrence_id",
            }
        ),
    },
    "invocation_adapter": {
        "structs": frozenset(),
        "enums": frozenset(),
        "functions": frozenset({"new_request", "is_locked"}),
    },
}
ABILITY_NAMES = {
    "Copy": "copy",
    "Drop": "drop",
    "Key": "key",
    "Store": "store",
}


class InterfaceError(Exception):
    """An interface cannot be generated or verified."""


def parse_args() -> argparse.Namespace:
    repository = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="directory containing the private package graph")
    parser.add_argument(
        "--output",
        type=Path,
        default=repository / "packages",
        help="interface package directory",
    )
    parser.add_argument("--sui", default="sui", help="Sui executable")
    parser.add_argument("--build-env", help="Move build environment")
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify generated files without changing them",
    )
    return parser.parse_args()


def validate_packages(root: Path) -> None:
    paths = {name: root / name for name, _ in PACKAGES}
    missing = [str(path) for path in paths.values() if not (path / "Move.toml").is_file()]
    if missing:
        raise InterfaceError(f"missing package manifests: {', '.join(missing)}")


def summarize(sui: str, packages: Path, output: Path, build_env: str | None) -> None:
    command = [
        sui,
        "move",
        "summary",
        "--path",
        str(packages / ROOT_PACKAGE),
        "--output-directory",
        str(output),
        "--doc",
        "--silence-warnings",
    ]
    if build_env:
        command.extend(("--build-env", build_env))
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError as error:
        raise InterfaceError(f"Sui executable not found: {sui}") from error
    except subprocess.CalledProcessError as error:
        raise InterfaceError("Sui package summary failed") from error


def load_summaries(root: Path) -> dict[str, dict[str, dict[str, Any]]]:
    summaries: dict[str, dict[str, dict[str, Any]]] = {}
    for _, address in PACKAGES:
        package_dir = root / address
        if not package_dir.is_dir():
            raise InterfaceError(f"summary is missing package {address}")
        modules: dict[str, dict[str, Any]] = {}
        for path in sorted(package_dir.glob("*.json")):
            module = json.loads(path.read_text())
            module_name = module["id"]["name"]
            modules[module_name] = module
        summaries[address] = modules
    return summaries


def select_declarations(
    declarations: dict[str, dict[str, Any]],
    selected: frozenset[str],
    module_id: str,
    kind: str,
) -> dict[str, dict[str, Any]]:
    missing = selected - declarations.keys()
    if missing:
        names = ", ".join(sorted(missing))
        raise InterfaceError(f"{module_id} is missing selected {kind}: {names}")
    return {name: declarations[name] for name in selected}


def select_interface_surface(
    summaries: dict[str, dict[str, dict[str, Any]]],
) -> dict[str, dict[str, dict[str, Any]]]:
    """Select the supported interface from the private package ABI."""
    selected = dict(summaries)
    workflow_modules = summaries["nexus_workflow"]
    missing_modules = WORKFLOW_INTERFACE.keys() - workflow_modules.keys()
    if missing_modules:
        names = ", ".join(sorted(missing_modules))
        raise InterfaceError(f"nexus_workflow is missing selected modules: {names}")

    selected_workflow = {}
    for module_name, surface in WORKFLOW_INTERFACE.items():
        module = workflow_modules[module_name]
        module_id = f"nexus_workflow::{module_name}"
        functions = select_declarations(
            module["functions"],
            surface["functions"],
            module_id,
            "functions",
        )
        non_public = sorted(
            name for name, function in functions.items() if function["visibility"] != "Public"
        )
        if non_public:
            names = ", ".join(non_public)
            raise InterfaceError(f"{module_id} selected functions are not public: {names}")

        selected_workflow[module_name] = {
            **module,
            "structs": select_declarations(
                module["structs"], surface["structs"], module_id, "structs"
            ),
            "enums": select_declarations(
                module["enums"], surface["enums"], module_id, "enums"
            ),
            "functions": functions,
        }

    selected["nexus_workflow"] = selected_workflow
    return selected


def ability_list(abilities: list[str]) -> str:
    if not abilities:
        return ""
    try:
        rendered = ", ".join(ABILITY_NAMES[ability] for ability in abilities)
    except KeyError as error:
        raise InterfaceError(f"unsupported ability: {error.args[0]}") from error
    return f" has {rendered}"


def type_parameters(parameters: list[dict[str, Any]]) -> str:
    if not parameters:
        return ""
    rendered = []
    for parameter in parameters:
        prefix = "phantom " if parameter.get("phantom", False) else ""
        constraints = parameter.get("constraints", [])
        constraint_text = ""
        if constraints:
            try:
                names = " + ".join(ABILITY_NAMES[item] for item in constraints)
            except KeyError as error:
                raise InterfaceError(f"unsupported type constraint: {error.args[0]}") from error
            constraint_text = f": {names}"
        rendered.append(f"{prefix}{parameter['name']}{constraint_text}")
    return f"<{', '.join(rendered)}>"


def move_type(value: Any, current_module: tuple[str, str]) -> str:
    if isinstance(value, str):
        return value
    if not isinstance(value, dict) or len(value) != 1:
        raise InterfaceError(f"unsupported Move type: {value!r}")

    if "vector" in value:
        return f"vector<{move_type(value['vector'], current_module)}>"
    if "NamedTypeParameter" in value:
        return value["NamedTypeParameter"]
    if "Reference" in value:
        mutable, inner = value["Reference"]
        qualifier = "&mut " if mutable else "&"
        return f"{qualifier}{move_type(inner, current_module)}"
    if "Datatype" in value:
        datatype = value["Datatype"]
        module = datatype["module"]
        module_id = (module["address"], module["name"])
        name = datatype["name"]
        if module_id != current_module:
            name = f"{module_id[0]}::{module_id[1]}::{name}"
        arguments = [
            move_type(argument.get("argument", argument), current_module)
            for argument in datatype.get("type_arguments", [])
        ]
        if arguments:
            name += f"<{', '.join(arguments)}>"
        return name
    raise InterfaceError(f"unsupported Move type: {value!r}")


def clean_doc(value: str | None) -> list[str]:
    if not value:
        return []
    doc = textwrap.dedent(value).strip()
    doc = re.sub(r"(?<=\w)-(?=\w)", " ", doc)
    return doc.splitlines()


def doc_comment(value: str | None, indent: int = 0) -> list[str]:
    prefix = " " * indent
    return [f"{prefix}///{f' {line}' if line else ''}" for line in clean_doc(value)]


def indexed(values: dict[str, dict[str, Any]]) -> list[tuple[str, dict[str, Any]]]:
    return sorted(values.items(), key=lambda item: item[1]["index"])


def has_dummy_field(fields: dict[str, Any]) -> bool:
    entries = fields["fields"]
    return (
        len(entries) == 1
        and "dummy_field" in entries
        and entries["dummy_field"]["type_"] == "bool"
    )


def render_struct(
    name: str,
    struct: dict[str, Any],
    current_module: tuple[str, str],
) -> list[str]:
    lines = doc_comment(struct.get("doc"))
    declaration = f"public struct {name}{type_parameters(struct['type_parameters'])}"
    abilities = ability_list(struct["abilities"])
    fields = struct["fields"]

    if has_dummy_field(fields):
        if fields["positional_fields"]:
            lines.append(f"{declaration}(){abilities};")
        else:
            lines.append(f"{declaration}{abilities} {{}}")
        return lines

    ordered_fields = indexed(fields["fields"])
    if fields["positional_fields"]:
        field_types = ", ".join(
            move_type(field["type_"], current_module) for _, field in ordered_fields
        )
        lines.append(f"{declaration}({field_types}){abilities};")
        return lines

    if not ordered_fields:
        lines.append(f"{declaration}{abilities} {{}}")
        return lines

    lines.append(f"{declaration}{abilities} {{")
    for field_name, field in ordered_fields:
        lines.extend(doc_comment(field.get("doc"), 4))
        lines.append(f"    {field_name}: {move_type(field['type_'], current_module)},")
    lines.append("}")
    return lines


def render_variant(
    name: str,
    variant: dict[str, Any],
    current_module: tuple[str, str],
) -> list[str]:
    lines = doc_comment(variant.get("doc"), 4)
    fields = variant["fields"]
    ordered_fields = indexed(fields["fields"])
    if not ordered_fields:
        lines.append(f"    {name},")
        return lines
    if fields["positional_fields"]:
        field_types = ", ".join(
            move_type(field["type_"], current_module) for _, field in ordered_fields
        )
        lines.append(f"    {name}({field_types}),")
        return lines

    lines.append(f"    {name} {{")
    for field_name, field in ordered_fields:
        lines.extend(doc_comment(field.get("doc"), 8))
        lines.append(f"        {field_name}: {move_type(field['type_'], current_module)},")
    lines.append("    },")
    return lines


def render_enum(
    name: str,
    enum: dict[str, Any],
    current_module: tuple[str, str],
) -> list[str]:
    lines = doc_comment(enum.get("doc"))
    declaration = f"public enum {name}{type_parameters(enum['type_parameters'])}"
    declaration += ability_list(enum["abilities"])
    lines.append(f"{declaration} {{")
    for variant_name, variant in indexed(enum["variants"]):
        lines.extend(render_variant(variant_name, variant, current_module))
    lines.append("}")
    return lines


def render_function(
    name: str,
    function: dict[str, Any],
    current_module: tuple[str, str],
) -> list[str]:
    if function["entry"]:
        raise InterfaceError(f"public entry function is not supported: {current_module}::{name}")

    lines = doc_comment(function.get("doc"))
    declaration = f"public native fun {name}{type_parameters(function['type_parameters'])}"
    parameters = function["parameters"]
    if parameters:
        lines.append(f"{declaration}(")
        for parameter in parameters:
            parameter_type = move_type(parameter["type_"], current_module)
            lines.append(f"    {parameter['name']}: {parameter_type},")
        closing = ")"
    else:
        closing = f"{declaration}()"

    returns = [move_type(value, current_module) for value in function["return_"]]
    if len(returns) == 1:
        closing += f": {returns[0]}"
    elif returns:
        closing += f": ({', '.join(returns)})"
    lines.append(f"{closing};")
    return lines


def render_module(module: dict[str, Any]) -> str:
    address = module["id"]["address"]
    name = module["id"]["name"]
    current_module = (address, name)
    lines = [
        f"module {address}::{name};",
        "",
        f"//! Interface for [`{address}::{name}`].",
        "//!",
        "//! Calls resolve to the published package.",
    ]

    datatypes = [
        (value["index"], "struct", datatype_name, value)
        for datatype_name, value in module["structs"].items()
    ]
    datatypes.extend(
        (value["index"], "enum", datatype_name, value)
        for datatype_name, value in module["enums"].items()
    )
    for _, kind, datatype_name, value in sorted(datatypes):
        lines.append("")
        if kind == "struct":
            lines.extend(render_struct(datatype_name, value, current_module))
        else:
            lines.extend(render_enum(datatype_name, value, current_module))

    functions = [
        (value["source_index"], function_name, value)
        for function_name, value in module["functions"].items()
        if value["visibility"] == "Public"
    ]
    for _, function_name, function in sorted(functions):
        lines.append("")
        lines.extend(render_function(function_name, function, current_module))
    lines.append("")
    return "\n".join(lines)


def generated_files(
    source: Path,
    summaries: dict[str, dict[str, dict[str, Any]]],
) -> dict[Path, str]:
    files: dict[Path, str] = {}
    for package_name, address in PACKAGES:
        package_root = Path(package_name)
        files[package_root / "Move.toml"] = (source / package_name / "Move.toml").read_text()
        publication = source / package_name / "Published.toml"
        if publication.is_file():
            files[package_root / "Published.toml"] = publication.read_text()
        for module_name, module in summaries[address].items():
            files[package_root / "sources" / f"{module_name}.move"] = render_module(module)
    return files


def format_files(sui: str, files: dict[Path, str]) -> dict[Path, str]:
    formatted = dict(files)
    with tempfile.TemporaryDirectory(prefix="nexus_interface_format_") as temp:
        root = Path(temp)
        move_files = []
        for relative, content in files.items():
            if relative.suffix != ".move":
                continue
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
            move_files.append(path)

        command = [
            sui,
            "move",
            "format",
            "--no-config",
            "--use-module-label",
            "--write",
            *map(str, move_files),
        ]
        try:
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
        except subprocess.CalledProcessError as error:
            raise InterfaceError("Move interface formatting failed") from error

        for relative in formatted:
            if relative.suffix == ".move":
                formatted[relative] = (root / relative).read_text()
    return formatted


def show_diff(path: Path, actual: str, expected: str) -> None:
    diff = difflib.unified_diff(
        actual.splitlines(),
        expected.splitlines(),
        fromfile=str(path),
        tofile=f"generated/{path}",
        lineterm="",
    )
    for line in diff:
        print(line)


def sync_files(output: Path, files: dict[Path, str], check: bool) -> None:
    expected = set(files)
    actual_sources = set()
    for package, _ in PACKAGES:
        actual_sources.update(
            path.relative_to(output)
            for path in (output / package / "sources").glob("*.move")
            if path.is_file()
        )
    extras = sorted(actual_sources - expected)
    differences = []

    for relative, content in sorted(files.items()):
        path = output / relative
        actual = path.read_text() if path.is_file() else ""
        if actual == content:
            continue
        differences.append(relative)
        if check:
            show_diff(relative, actual, content)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)

    if check and extras:
        for relative in extras:
            print(f"unexpected generated source: {relative}")
    elif not check:
        for relative in extras:
            (output / relative).unlink()

    if check and (differences or extras):
        raise InterfaceError("generated interfaces are not current")


def normalize_fields(fields: dict[str, Any]) -> dict[str, Any]:
    return {
        "positional_fields": fields["positional_fields"],
        "fields": [
            {"name": name, "type": field["type_"]}
            for name, field in indexed(fields["fields"])
        ],
    }


def normalize_datatype(datatype: dict[str, Any]) -> dict[str, Any]:
    return {
        "abilities": datatype["abilities"],
        "type_parameters": datatype["type_parameters"],
        "fields": normalize_fields(datatype["fields"]),
    }


def normalize_enum(enum: dict[str, Any]) -> dict[str, Any]:
    return {
        "abilities": enum["abilities"],
        "type_parameters": enum["type_parameters"],
        "variants": [
            {"name": name, "fields": normalize_fields(variant["fields"])}
            for name, variant in indexed(enum["variants"])
        ],
    }


def normalize_function(function: dict[str, Any]) -> dict[str, Any]:
    return {
        "entry": function["entry"],
        "type_parameters": function["type_parameters"],
        "parameters": [
            {"name": parameter["name"], "type": parameter["type_"]}
            for parameter in function["parameters"]
        ],
        "return": function["return_"],
    }


def public_abi(
    summaries: dict[str, dict[str, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    abi: dict[str, dict[str, Any]] = {}
    for _, address in PACKAGES:
        for module_name, module in summaries[address].items():
            module_id = f"{address}::{module_name}"
            abi[module_id] = {
                "structs": {
                    name: normalize_datatype(value)
                    for name, value in sorted(module["structs"].items())
                },
                "enums": {
                    name: normalize_enum(value)
                    for name, value in sorted(module["enums"].items())
                },
                "functions": {
                    name: normalize_function(value)
                    for name, value in sorted(module["functions"].items())
                    if value["visibility"] == "Public"
                },
            }
    return abi


def verify_abi(
    expected_summaries: dict[str, dict[str, dict[str, Any]]],
    interface: dict[str, dict[str, dict[str, Any]]],
) -> None:
    source_abi = public_abi(expected_summaries)
    interface_abi = public_abi(interface)
    if source_abi == interface_abi:
        return
    expected_lines = json.dumps(source_abi, indent=2, sort_keys=True).splitlines()
    actual_lines = json.dumps(interface_abi, indent=2, sort_keys=True).splitlines()
    for line in difflib.unified_diff(
        expected_lines,
        actual_lines,
        fromfile="selected private public ABI",
        tofile="generated interface ABI",
        lineterm="",
    ):
        print(line)
    raise InterfaceError("generated interface ABI does not match the selected private ABI")


def interface_stats(summaries: dict[str, dict[str, dict[str, Any]]]) -> tuple[int, int, int]:
    modules = functions = datatypes = 0
    for _, address in PACKAGES:
        for module in summaries[address].values():
            modules += 1
            functions += sum(
                function["visibility"] == "Public" for function in module["functions"].values()
            )
            datatypes += len(module["structs"]) + len(module["enums"])
    return modules, functions, datatypes


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    if source == output or source in output.parents or output in source.parents:
        raise InterfaceError("source and output must be separate package graphs")
    validate_packages(source)

    with tempfile.TemporaryDirectory(prefix="nexus_interface_source_") as source_temp:
        source_summary_root = Path(source_temp)
        summarize(args.sui, source, source_summary_root, args.build_env)
        source_summaries = load_summaries(source_summary_root)
        selected_summaries = select_interface_surface(source_summaries)
        files = format_files(args.sui, generated_files(source, selected_summaries))
        sync_files(output, files, args.check)

    with tempfile.TemporaryDirectory(prefix="nexus_interface_output_") as output_temp:
        output_summary_root = Path(output_temp)
        summarize(args.sui, output, output_summary_root, args.build_env)
        output_summaries = load_summaries(output_summary_root)
        verify_abi(selected_summaries, output_summaries)

    modules, functions, datatypes = interface_stats(selected_summaries)
    action = "Verified" if args.check else "Generated"
    print(f"{action} {modules} modules, {datatypes} data types, and {functions} public functions")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except InterfaceError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
