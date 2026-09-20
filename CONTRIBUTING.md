# Contributing

Contributions are welcome.

Before opening a pull request:

```bash
make check
make shellcheck
```

Please keep the main daemon dependency-light and compatible with standard GNU/Linux userland tools. New distribution-specific behavior should degrade gracefully when unavailable.

When changing DDC/CI behavior, favor recoverability over aggressive power-off semantics. In particular, avoid making VCP D6 `05` the default because some monitors may no longer answer DDC commands after entering that state.
