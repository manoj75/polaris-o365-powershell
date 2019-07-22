function Get-PolarisO365Users() {
    <#
    .SYNOPSIS

    Returns all O365 users for a given subscription in a given Polaris instance.

    .DESCRIPTION

    Returns an array of Office 365 users from a given subscription and Polaris instance, taking
    an API token, Polaris URL, and subscription ID.

    .PARAMETER Token
    Polaris API Token.

    .PARAMETER PolarisURL
    The URL for the Polaris instance in the form 'https://myurl'

    .PARAMETER SubscriptionID
    The Polaris subscription ID for a given O365 subscription. Can be obtained with the
    'Get-PolarisO365Subscriptions' command.

    .INPUTS

    None. You cannot pipe objects to Get-PolarisO365Users.

    .OUTPUTS

    System.Object. Get-PolarisO365Users returns an array containing the ID, Name,
    email address, and SLA details for the returned O365 users.

    .EXAMPLE

    PS> Get-PolarisO365Users -Token $token -PolarisURL $url -SubscriptionId $my_sub.id

    name                   : Milan Kundera
    id                     : 12341234-1234-1234-abcd-123456789012
    emailAddress           : milan.kundera@mydomain.onmicrosoft.com
    slaAssignment          : Direct
    effectiveSlaDomainName : Gold
    #>

    param(
        [Parameter(Mandatory=$True)]
        [String]$Token,
        [Parameter(Mandatory=$True)]
        [String]$PolarisURL,
        [Parameter(Mandatory=$True)]
        [String]$SubscriptionId
    )

    $headers = @{
        'Content-Type' = 'application/json';
        'Accept' = 'application/json';
        'Authorization' = $('Bearer '+$Token);
    }

    $endpoint = $PolarisURL + '/api/graphql'

    # get users

    $node_array = @()

    $payload = @{
        "operationName" = "O365UserList";
        "query" = "query O365UserList(`$first: Int!, `$after: String, `$id: UUID!, `$filter: [Filter!]!, `$sortBy: HierarchySortByField, `$sortOrder: HierarchySortOrder) {
            o365Org(fid: `$id) {
                id
                childConnection(first: `$first, filter: `$filter, sortBy: `$sortBy, sortOrder: `$sortOrder, after: `$after) {
                    edges {
                        node {
                            id
                            name
                            emailAddress
                            effectiveSlaDomain {
                                name
                            }
                            authorizedOperations {
                                id
                                operations
                                __typename
                            }
                            childConnection(filter: []) {
                                nodes {
                                    id
                                    name
                                    objectType
                                }
                            }
                            slaAssignment
                        }
                    }
                    pageInfo {
                        endCursor
                        hasNextPage
                        hasPreviousPage
                    }
                }
            }
        }";
        "variables" = @{
            "after" = $null;
            "filter" = @(
                @{
                    "field" = "IS_RELIC";
                    "texts" = @("false")
                };
            )
            "first" = 100;
            "id" = $SubscriptionId;
            "sortBy" = "EMAIL_ADDRESS";
            "sortOrder" = "ASC";
        }
    }
    $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers
    $node_array += $response.data.o365Org.childConnection.edges.node
    # get all pages of results
    while ($response.data.o365Org.childConnection.pageInfo.hasNextPage) {
        $payload.variables.after = $response.data.o365Org.childConnection.pageInfo.endCursor
        $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers
        $node_array += $response.data.o365Org.childConnection.edges.node
    }

    $user_details = @()

    foreach ($node in $node_array) {
        $row = '' | Select-Object name,id,emailAddress,slaAssignment,effectiveSlaDomainName
        $row.name = $node.name
        $row.id = $node.id
        $row.emailAddress = $node.emailAddress
        $row.slaAssignment = $node.slaAssignment
        $row.effectiveSlaDomainName = $node.effectiveSlaDomain.name
        $user_details += $row
    }

    return $user_details
}

function Get-PolarisO365User() {
    <#
    .SYNOPSIS

    Returns a filtered list of O365 users for a given subscription in a given Polaris instance.

    .DESCRIPTION

    Returns a filtered list of Office 365 users from a given subscription and Polaris instance, taking
    an API token, Polaris URL, subscription ID, and search string.

    .PARAMETER Token
    Polaris API Token.

    .PARAMETER PolarisURL
    The URL for the Polaris instance in the form 'https://myurl'

    .PARAMETER SubscriptionID
    The Polaris subscription ID for a given O365 subscription. Can be obtained with the
    'Get-PolarisO365Subscriptions' command.

    .PARAMETER SearchString
    Search string, used to filter user's name or email address.

    .INPUTS

    None. You cannot pipe objects to Get-PolarisO365User.

    .OUTPUTS

    System.Object. Get-PolarisO365User returns an array containing the ID, Name,
    email address, and SLA details for the returned O365 users.

    .EXAMPLE

    PS> Get-PolarisO365User -Token $token -PolarisURL $url -SubscriptionId $my_sub.id -SearchString 'Milan'

    name                   : Milan Kundera
    id                     : 12341234-1234-1234-abcd-123456789012
    emailAddress           : milan.kundera@mydomain.onmicrosoft.com
    slaAssignment          : Direct
    effectiveSlaDomainName : Gold
    #>

    param(
        [Parameter(Mandatory=$True)]
        [String]$Token,
        [Parameter(Mandatory=$True)]
        [String]$PolarisURL,
        [Parameter(Mandatory=$True)]
        [String]$SubscriptionId,
        [Parameter(Mandatory=$True)]
        [String]$SearchString
    )

    $headers = @{
        'Content-Type' = 'application/json';
        'Accept' = 'application/json';
        'Authorization' = $('Bearer '+$Token);
    }

    $endpoint = $PolarisURL + '/api/graphql'

    # get users

    $node_array = @()

    $payload = @{
        "operationName" = "O365UserList";
        "variables" = @{
            "id" = $SubscriptionId;
            "first" = 100;
            "filter" = @(
                @{
                    "field" = "IS_RELIC";
                    "texts" = @("false");
                },
                @{
                    "field" = "NAME_OR_EMAIL_ADDRESS";
                    "texts" = @($SearchString);
                }
            );
            "sortBy" = "EMAIL_ADDRESS";
            "sortOrder" = "ASC";
        };
        "query" = "query O365UserList(`$first: Int!, `$after: String, `$id: UUID!, `$filter: [Filter!]!, `$sortBy: HierarchySortByField, `$sortOrder: HierarchySortOrder) {
            o365Org(fid: `$id) {
                id
                childConnection(first: `$first, filter: `$filter, sortBy: `$sortBy, sortOrder: `$sortOrder, after: `$after) {
                    edges {
                        node {
                            id
                            name
                            emailAddress
                            effectiveSlaDomain {
                                name
                            }
                            authorizedOperations {
                                id
                                operations
                            }
                            childConnection(filter: []) {
                                nodes {
                                    id
                                    name
                                    objectType
                                }
                            }
                            slaAssignment
                        }
                    }
                    pageInfo {
                        endCursor
                        hasNextPage
                        hasPreviousPage
                    }
                }
            }
        }"
    }
    $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers
    $node_array += $response.data.o365Org.childConnection.edges.node
    # get all pages of results
    while ($response.data.o365Org.childConnection.pageInfo.hasNextPage) {
        $payload.variables.after = $response.data.o365Org.childConnection.pageInfo.endCursor
        $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers
        $node_array += $response.data.o365Org.childConnection.edges.node
    }

    $user_details = @()

    foreach ($node in $node_array) {
        $row = '' | Select-Object name,id,emailAddress,slaAssignment,effectiveSlaDomainName
        $row.name = $node.name
        $row.id = $node.id
        $row.emailAddress = $node.emailAddress
        $row.slaAssignment = $node.slaAssignment
        $row.effectiveSlaDomainName = $node.effectiveSlaDomain.name
        $user_details += $row
    }

    return $user_details
}