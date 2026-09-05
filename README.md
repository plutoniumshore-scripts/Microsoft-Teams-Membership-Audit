# Microsoft Teams Membership Audit

Microsoft Teams Membership Audit is a PowerShell utility for identifying and exporting the Microsoft Teams that a specified Microsoft 365 user is directly a member of.

The script uses Microsoft Graph with interactive delegated authentication and requests only the read permission required to retrieve basic Team membership information.

**If you find anything here useful, please consider donating:**

https://paypal.me/plutoniumshore

## Intended Use

This utility is intended for Microsoft 365 administrators, support technicians, and other authorized users who need a quick way to determine which Microsoft Teams a particular user belongs to.

The script is read only. It does not create, modify, archive, delete, or change membership in any Team.

Results are displayed in PowerShell and exported to CSV for troubleshooting, access reviews, account transitions, documentation, or other administrative work.

## Who This Is For

This project may be useful to:

* Microsoft 365 and Teams administrators reviewing user access.
* Help desk and support personnel troubleshooting Team membership questions.
* Identity and access administrators performing account reviews or transitions.
* Auditors or technical staff who need a simple export of a user's direct Team memberships.

## What It Does

The script:

* Authenticates interactively to Microsoft Graph.
* Accepts a Microsoft 365 user principal name such as `user@example.com`.
* Retrieves the Teams where that user is a direct member.
* Reports Team display name, Team ID, description, archive status, and tenant ID when returned by Microsoft Graph.
* Displays the number of memberships found.
* Exports the results to a timestamped CSV file.
* Disconnects the Microsoft Graph session when the operation finishes or fails.

The script performs read only Microsoft Graph operations.

## Requirements

* Windows 11 is the primary target environment for this release.
* Windows PowerShell 5.1 or PowerShell 7+.
* `Microsoft.Graph.Authentication` PowerShell module.
* `Microsoft.Graph.Teams` PowerShell module.
* A Microsoft 365 work or school account authorized to query Teams membership information.
* Internet access to Microsoft Graph.

Install the required modules if necessary:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Teams -Scope CurrentUser
```

The script checks for the required modules but does not install or modify PowerShell modules automatically.

## Microsoft Graph Permissions

The script requests the following delegated Microsoft Graph permission:

```text
Team.ReadBasic.All
```

Microsoft documents `Team.ReadBasic.All` as the least privileged delegated permission for listing the Teams a user has joined.

The script does not request Microsoft Graph write permissions. Organizational consent requirements, Conditional Access policies, and other tenant security controls can still affect whether authentication succeeds.

Microsoft documentation for the underlying operation:

https://learn.microsoft.com/en-us/graph/api/user-list-joinedteams?view=graph-rest-1.0

## Usage

Run against a specific user:

```powershell
.\Get-TeamsMembershipAudit.ps1 -UserPrincipalName 'user@example.com'
```

Specify an output directory:

```powershell
.\Get-TeamsMembershipAudit.ps1 `
    -UserPrincipalName 'user@example.com' `
    -OutputDirectory 'C:\Reports'
```

Running without a user parameter prompts for the UPN interactively:

```powershell
.\Get-TeamsMembershipAudit.ps1
```

## Output

By default, reports are written to an `output` directory beside the script.

A report is written using a timestamped filename similar to:

```text
TeamsMembership_user_example.com_20260905_083015.csv
```

The CSV contains:

| Field | Description |
| --- | --- |
| `CheckedUserUpn` | User whose memberships were queried. |
| `MembershipFound` | Whether the row represents an actual Team membership. |
| `TeamDisplayName` | Microsoft Team display name. |
| `TeamId` | Microsoft Graph Team identifier. |
| `TeamDescription` | Team description returned by Microsoft Graph. |
| `TeamIsArchived` | Whether Microsoft Graph reports the Team as archived. |
| `TeamTenantId` | Tenant identifier returned with the Team. |

If no direct memberships are found, the CSV still contains a single result row with `MembershipFound` set to `False`. This makes an empty result explicit rather than producing an ambiguous blank file.

## Limitations

The Microsoft Graph `joinedTeams` operation reports Teams where the specified user is a direct member.

Microsoft documents that this operation does not return the host Team of a shared channel merely because the user has access to that shared channel. Additional Microsoft Graph operations are required to build a complete inventory of every Teams resource a user may be able to access.

This project should therefore be treated as a direct Teams membership audit rather than a complete Teams access entitlement report.

## Security Notes

The script does not contain credentials, tenant IDs, usernames, passwords, client secrets, private server names, or environment specific addresses.

Authentication is performed interactively through Microsoft Graph.

Generated CSV reports can contain organizational information including user principal names, Team names, Team descriptions, Team IDs, and tenant identifiers. Treat generated reports according to the security requirements of the Microsoft 365 environment being audited.

The default `output` directory and CSV files are excluded from the repository through `.gitignore` to reduce the chance of generated organizational data being committed accidentally.

Review any report before sharing it publicly.

## Attribution and AI Assistance

Some portions of this project may be adaptations of, inspired by, or derived from publicly available examples, documentation, community discussions, or other prior work. AI tools may also have been used to help create, review, troubleshoot, document, format, or refine code.

Specific third party sources or license requirements are identified in the relevant file or documentation when applicable. Third party software, services, and APIs used by the project, including Microsoft Graph and Microsoft Teams, remain subject to their own licenses and terms.

## License

This repository is provided under the MIT License. See [`LICENSE`](./LICENSE) for the applicable terms and warranty disclaimer.
