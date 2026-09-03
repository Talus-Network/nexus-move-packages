# Nexus kernel interface

Public Move interface for the Nexus runtime authority package.

Most TAPs receive kernel types through another Nexus package and do not import this package directly. An embedded application that calls Scheduler functions from Move source imports `RuntimeAuthority`, so Move requires a direct kernel dependency.

The kernel currently has no public MVR name. Pin this repository at the same release used by the other Nexus dependencies:

<!-- markdownlint-disable MD013 -->

```toml
[dependencies]
nexus_kernel = { git = "https://github.com/Talus-Network/nexus-move-packages", subdir = "packages/kernel", rev = "testnet/v1" }
```

<!-- markdownlint-enable MD013 -->

When developing inside this repository, use a local path:

```toml
[dependencies]
nexus_kernel = { local = "../../../packages/kernel" }
```

Application scheduling normally receives the shared deployment authority as a function argument:

```move
public fun schedule(
    authority: &nexus_kernel::runtime_authority::RuntimeAuthority,
    // Application and Nexus objects follow.
) {
    // Pass authority to the published Scheduler function.
}
```

Do not construct a production authority. Use the authority object from the active Nexus object map. A unit test may add a `#[test_only]` extension that constructs the smallest authority state read by its scheduling path.

This directory contains an interface, not the private Nexus implementation. Calls made by ordinary `sui move test` reach unavailable stub bodies. Use `nexus tap test` to execute the selected published Nexus bytecode locally.
