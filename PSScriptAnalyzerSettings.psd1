@{
    # Settings for PSScriptAnalyzer (CI + pre-commit).
    # Goal: catch real bugs, not fight the documented style of this library
    # (StrictMode Latest, comment-based help, shared logger, Write-Host tables).
    IncludeRules = @(
        # Correctness
        'PSReviewUnusedParameter'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseCorrectCasing'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingSecureStringAsPlainText'
        'PSUseConsistentWhitespace'
        # Style (low noise)
        'PSAvoidUsingPositionalParameters'
    )

    # Rules excluded deliberately, with reason:
    # - PSAvoidUsingEmptyCatchBlock: the utilities use many intentional
    #   `catch {}` blocks for best-effort probes (registry reads, `Get-Command`,
    #   `Get-ItemProperty`) and for log lines that must never fail the script.
    # - PSAvoidUsingWriteHost: the utilities print human-readable tables on purpose.
    # - PSAvoidUsingCmdletAliases: single-letter aliases are avoided in the
    #   utilities already; some composite keys in tests use aliases in hashtables.
    ExcludeRules = @('PSAvoidUsingEmptyCatchBlock')
}
