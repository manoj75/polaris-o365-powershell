function Get-PolarisToken() {
    <#
    .SYNOPSIS

    Returns an API access token for a given Polaris instance.

    .DESCRIPTION

    Returns an API access token for a given Polaris instance, taking the URL, username and password.

    .PARAMETER Username
    Polaris username.

    .PARAMETER Password
    Polaris password.

    .PARAMETER Password
    The URL for the Polaris instance in the form 'https://myurl'

    .INPUTS

    None. You cannot pipe objects to Get-PolarisToken.

    .OUTPUTS

    System.String. Get-PolarisToken returns a string containing the access token.

    .EXAMPLE

    PS> $token = Get-PolarisToken -Username $username -Password $password -PolarisURL $url
    #>

    param(
        [Parameter(Mandatory=$True)]
        [String]$Username,
        [Parameter(Mandatory=$True)]
        [String]$Password,
        [Parameter(Mandatory=$True)]
        [String]$PolarisURL
    )
    $headers = @{
        'Content-Type' = 'application/json';
        'Accept' = 'application/json';
    }
    $payload = @{
        "username" = $Username;
        "password" = $Password;
    }
    $endpoint = $PolarisURL + '/api/session'
    $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers
    return $response.access_token
}

function Get-PolarisSLA() {
    <#
    .SYNOPSIS

    Returns the SLA Domains from a given Polaris instance.

    .DESCRIPTION

    Returns SLA Domains for a given Polaris instance. This can be used to return
    based on a name query, by using the 'Name' parameter.

    .PARAMETER Token
    Polaris access token, get this using the 'Get-PolarisToken' command.

    .PARAMETER PolarisURL
    The URL for the Polaris instance in the form 'https://myurl'

    .PARAMETER Name
    Optional. The name of the required SLA Domain. If none is provided, all
    SLAs are returned.

    .INPUTS

    None. You cannot pipe objects to Get-PolarisSLA.

    .OUTPUTS

    System.Object. Get-PolarisSLA returns an array containing the ID, Name,
    and Description of the returned SLA Domains.

    .EXAMPLE

    PS> Get-PolarisSLA -Token $token -PolarisURL $url -Name 'Bronze'
    name   id                                   description
    ----   --                                   -----------
    Bronze 00000000-0000-0000-0000-000000000002 Bronze SLA
    #>

    param(
        [Parameter(Mandatory=$True)]
        [String]$Token,
        [Parameter(Mandatory=$True)]
        [String]$PolarisURL,
        [Parameter(Mandatory=$False)]
        [String]$Name
    )

    $headers = @{
        'Content-Type' = 'application/json';
        'Accept' = 'application/json';
        'Authorization' = $('Bearer '+$Token);
    }

    $endpoint = $PolarisURL + '/api/graphql'

    $payload = @{
        "operationName" = "SLAList";
        "variables" = @{"first" = 20; "name" = $Name};
        "query" = "query SLAList(`$after: String, `$first: Int, `$name: String) {
            globalSlaConnection(after: `$after, first: `$first, filter: [{field: NAME, text: `$name}]) {
                edges {
                    node {
                        id
                        name
                    }
                }
                pageInfo {
                    endCursor
                    hasNextPage
                    hasPreviousPage
                }
            }
        }"
    }

    $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers

    $sla_detail = @()

    foreach ($edge in $response.data.globalSlaConnection.edges) {
        $row = '' | Select-Object name,id,description
        $row.name = $edge.node.name
        $row.id = $edge.node.id
        $sla_detail += $row
    }

    return $sla_detail
}