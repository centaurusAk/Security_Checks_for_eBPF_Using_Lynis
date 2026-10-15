# Security Checks for eBPF Using Lynis

**Author:** Neerav Ahuja

This repository contains a reference Lynis plugin and two alternative versions that extend its checks for eBPF-related kernel settings. Option 1 improves the runtime checks. Option 2 includes those checks and also looks for persistent sysctl declarations in configuration files. The options are alternatives, so test them one at a time.

## What is included

- `reference_plugin_kernel_ebpf_harden`: the original reference plugin, kept for comparison.
- `option1/plugin_kernel_ebpf_harden_enhanced_runtime`: improved checks for the current runtime values of eBPF JIT hardening and unprivileged eBPF restrictions.
- `option2/plugin_kernel_ebpf_harden_enhanced_persistence`: the runtime checks plus an inventory of matching persistent sysctl declarations.
- `run_lynis_option.sh`: runs one enhanced plugin in a temporary plugin directory, without replacing the plugins under `/etc/lynis/plugins`.
- `tests/`: local mock tests and sample outputs used to exercise selected code paths.

## Run the local tests

From the repository directory, run:

```sh
sh tests/run_mock_tests.sh
```

These tests check shell syntax and selected secure and warning branches with mock values. They do not change kernel settings, and they are not a substitute for testing against a live Lynis installation.

## Run an enhanced plugin with Lynis

Lynis must be installed, and the audit will ask for `sudo` authorization. To run Option 1:

```sh
sh ./run_lynis_option.sh 1
```

To run Option 2:

```sh
sh ./run_lynis_option.sh 2
```

The runner creates a temporary profile and plugin directory, enables only the selected option, runs a system audit, and cleans up the temporary files when it exits. It does not overwrite the plugins in `/etc/lynis/plugins`. You can also pass an existing profile as a second argument, for example `sh ./run_lynis_option.sh 1 /path/to/da1_test.prf`.

## Notes on interpreting results

The two enhanced plugins were tested separately with Lynis 3.1.6. The observed runs reported a warning for eBPF JIT hardening and showed the unprivileged eBPF restriction as enabled. Option 2 did not find explicit persistent declarations for either setting in the configuration files it inspected. These findings describe that test environment; they do not mean every system will have the same results or that the full-system audit will be warning-free.

The original reference plugin includes an `AddScore 2` call. In the tested Lynis 3.1.6 environment, that call produced an `AddScore: not found` message, so the enhanced options avoid relying on it. The reference plugin is left unchanged for comparison.
