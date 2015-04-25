#  AzureWebSitePublishModule.psm1 は Windows PowerShell スクリプト モジュールです。このモジュールは、Web アプリケーションのライフ サイクル管理を自動化する Windows PowerShell 関数をエクスポートします。この関数をそのまま使用するか、アプリケーションや公開環境用にカスタマイズすることができます。

Set-StrictMode -Version 3

# 元のサブスクリプションを保存する変数。
$Script:originalCurrentSubscription = $null

# 元のストレージ アカウントを保存する変数。
$Script:originalCurrentStorageAccount = $null

# ユーザーが指定したサブスクリプションのストレージ アカウントを保存する変数。
$Script:originalStorageAccountOfUserSpecifiedSubscription = $null

# サブスクリプション名を保存する変数。
$Script:userSpecifiedSubscription = $null


<#
.SYNOPSIS
メッセージの先頭に日付と時刻を付加します。

.DESCRIPTION
メッセージの先頭に日付と時刻を付加します。この関数は、Error および Verbose ストリームに書き込まれるメッセージを対象に設計されています。

.PARAMETER  Message
日付のないメッセージを指定します。

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Format-DevTestMessageWithTime -Message "ディレクトリへのファイル $filename の追加"
2/5/2014 1:03:08 PM - ディレクトリへのファイル $filename の追加

.LINK
Write-VerboseWithTime

.LINK
Write-ErrorWithTime
#>
function Format-DevTestMessageWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    return ((Get-Date -Format G)  + ' - ' + $Message)
}


<#

.SYNOPSIS
現在時刻が先頭に付加されたエラー メッセージを書き込みます。

.DESCRIPTION
現在時刻が先頭に付加されたエラー メッセージを書き込みます。この関数は、Format-DevTestMessageWithTime 関数を呼び出して、先頭に時刻を付加してからメッセージを Error ストリームに書き込みます。

.PARAMETER  Message
エラー メッセージ呼び出しのメッセージを指定します。関数にメッセージ文字列をパイプできます。

.INPUTS
System.String

.OUTPUTS
なし。関数は Error ストリームに書き込みます。

.EXAMPLE
PS C:> Write-ErrorWithTime -Message "Failed. Cannot find the file."

Write-Error: 2/6/2014 8:37:29 AM - Failed. Cannot find the file.
 + CategoryInfo     : NotSpecified: (:) [Write-Error], WriteErrorException
 + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

.LINK
Write-Error

#>
function Write-ErrorWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Error
}


<#
.SYNOPSIS
現在時刻が先頭に付加された詳細メッセージを書き込みます。

.DESCRIPTION
現在時刻が先頭に付加された詳細メッセージを書き込みます。Write-Verbose を呼び出すので、Verbose パラメーターを指定してスクリプトを実行する場合または VerbosePreference 設定を Continue に設定している場合にのみ、メッセージが表示されます。

.PARAMETER  Message
詳細メッセージ呼び出しのメッセージを指定します。関数にメッセージ文字列をパイプできます。

.INPUTS
System.String

.OUTPUTS
なし。関数は Verbose ストリームに書き込みます。

.EXAMPLE
PS C:> Write-VerboseWithTime -Message "The operation succeeded."
PS C:>
PS C:\> Write-VerboseWithTime -Message "The operation succeeded." -Verbose
VERBOSE: 1/27/2014 11:02:37 AM - The operation succeeded.

.EXAMPLE
PS C:\ps-test> "The operation succeeded." | Write-VerboseWithTime -Verbose
VERBOSE: 1/27/2014 11:01:38 AM - The operation succeeded.

.LINK
Write-Verbose
#>
function Write-VerboseWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Verbose
}


<#
.SYNOPSIS
現在時刻が先頭に付加されたホスト メッセージを書き込みます。

.DESCRIPTION
この関数は、現在時刻が先頭に付加されたメッセージをホスト プログラム (Write-Host) に書き込みます。ホスト プログラムへの書き込み結果は一定ではありません。Windows PowerShell をホストするほとんどのプログラムは、このようなメッセージを標準出力に書き込みます。

.PARAMETER  Message
日付のない基本メッセージを指定します。関数にメッセージ文字列をパイプできます。

.INPUTS
System.String

.OUTPUTS
なし。関数はメッセージをホスト プログラムに書き込みます。

.EXAMPLE
PS C:> Write-HostWithTime -Message "操作が成功しました。"
1/27/2014 11:02:37 AM - 操作が成功しました。

.LINK
Write-Host
#>
function Write-HostWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    
    if ((Get-Variable SendHostMessagesToOutput -Scope Global -ErrorAction SilentlyContinue) -and $Global:SendHostMessagesToOutput)
    {
        if (!(Get-Variable -Scope Global AzureWebAppPublishOutput -ErrorAction SilentlyContinue) -or !$Global:AzureWebAppPublishOutput)
        {
            New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
        }

        $Global:AzureWebAppPublishOutput += $Message | Format-DevTestMessageWithTime
    }
    else 
    {
        $Message | Format-DevTestMessageWithTime | Write-Host
    }
}


<#
.SYNOPSIS
プロパティまたはメソッドがオブジェクトのメンバーである場合は $true を返します。それ以外の場合は $false です。

.DESCRIPTION
プロパティまたはメソッドがオブジェクトのメンバーである場合は $true を返します。クラスの静的メソッドの場合、およびビュー (PSBase、PSObject など) の場合、この関数は $false を返します。

.PARAMETER  Object
テスト内のオブジェクトを指定します。オブジェクトを含んでいる変数またはオブジェクトを返す式を入力します。この関数には、[DateTime] などの型を指定することも、オブジェクトをパイプすることもできません。

.PARAMETER  Member
テスト内のプロパティまたはメソッドの名前を指定します。メソッドを指定する場合は、メソッド名の後のかっこを省略します。

.INPUTS
なし。この関数はパイプラインからの入力を受け取りません。

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Test-Member -Object (Get-Date) -Member DayOfWeek
True

.EXAMPLE
PS C:\> $date = Get-Date
PS C:\> Test-Member -Object $date -Member AddDays
True

.EXAMPLE
PS C:\> [DateTime]::IsLeapYear((Get-Date).Year)
True
PS C:\> Test-Member -Object (Get-Date) -Member IsLeapYear
False

.LINK
Get-Member
#>
function Test-Member
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [String]
        $Member
    )

    return $null -ne ($Object | Get-Member -Name $Member)
}


<#
.SYNOPSIS
Azure モジュールのバージョンが 0.7.4 以降の場合は $true を返します。それ以外の場合は $false です。

.DESCRIPTION
Test-AzureModuleVersion は、Azure モジュールのバージョンが 0.7.4 以降の場合は $true を返します。モジュールがインストールされていないか以前のバージョンの場合は、$false を返します。この関数にパラメーターはありません。

.INPUTS
なし

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModuleVersion
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
0      7      4      -1

PS C:\> Test-AzureModuleVersion
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Version]
        $Version
    )

    return ($Version.Major -gt 0) -or ($Version.Minor -gt 7) -or ($Version.Minor -eq 7 -and $Version.Build -ge 4)
}


<#
.SYNOPSIS
インストールされている Azure モジュールのバージョンが 0.7.4 以降の場合は $true を返します。

.DESCRIPTION
Test-AzureModule は、インストールされている Azure モジュールのバージョンが 0.7.4 以降の場合は $true を返します。モジュールがインストールされていないか以前のバージョンの場合は、$false を返します。この関数にパラメーターはありません。

.INPUTS
なし

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModule
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
    0      7      4      -1

PS C:\> Test-AzureModule
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModule
{
    [CmdletBinding()]

    $module = Get-Module -Name Azure

    if (!$module)
    {
        $module = Get-Module -Name Azure -ListAvailable

        if (!$module -or !(Test-AzureModuleVersion $module.Version))
        {
            return $false;
        }
        else
        {
            $ErrorActionPreference = 'Continue'
            Import-Module -Name Azure -Global -Verbose:$false
            $ErrorActionPreference = 'Stop'

            return $true
        }
    }
    else
    {
        return (Test-AzureModuleVersion $module.Version)
    }
}


<#
.SYNOPSIS
現在の Microsoft Azure サブスクリプションをスクリプト スコープ内の $Script:originalSubscription 変数に保存します。

.DESCRIPTION
Backup-Subscription 関数は、現在の Microsoft Azure サブスクリプション (Get-AzureSubscription -Current) とそのストレージ アカウント、このスクリプトによって変更されるサブスクリプション ($UserSpecifiedSubscription) とそのストレージ アカウントをスクリプト スコープ内に保存します。値を保存することで、現在のステータスが変更された場合に、Restore-Subscription などの関数を使用して、元の現在のサブスクリプションとストレージ アカウントを現在のステータスに復元できます。

.PARAMETER UserSpecifiedSubscription
新しいリソースを作成および公開するサブスクリプションの名前を指定します。関数によって、サブスクリプションとそのストレージ アカウントの名前がスクリプト スコープ内に保存されます。このパラメーターは必須です。

.INPUTS
なし

.OUTPUTS
なし

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso
PS C:\>

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso -Verbose
VERBOSE: Backup-Subscription: Start
VERBOSE: Backup-Subscription: Original subscription is Microsoft Azure MSDN - Visual Studio Ultimate
VERBOSE: Backup-Subscription: End
#>
function Backup-Subscription
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UserSpecifiedSubscription
    )

    Write-VerboseWithTime 'Backup-Subscription: 開始'

    $Script:originalCurrentSubscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue
    if ($Script:originalCurrentSubscription)
    {
        Write-VerboseWithTime ('Backup-Subscription: 元のサブスクリプション: ' + $Script:originalCurrentSubscription.SubscriptionName)
        $Script:originalCurrentStorageAccount = $Script:originalCurrentSubscription.CurrentStorageAccountName
    }
    
    $Script:userSpecifiedSubscription = $UserSpecifiedSubscription
    if ($Script:userSpecifiedSubscription)
    {        
        $userSubscription = Get-AzureSubscription -SubscriptionName $Script:userSpecifiedSubscription -ErrorAction SilentlyContinue
        if ($userSubscription)
        {
            $Script:originalStorageAccountOfUserSpecifiedSubscription = $userSubscription.CurrentStorageAccountName
        }        
    }

    Write-VerboseWithTime 'Backup-Subscription: 終了'
}


<#
.SYNOPSIS
スクリプト スコープ内の $Script:originalSubscription 変数に保存されている Microsoft Azure サブスクリプションを "current" ステータスに復元します。

.DESCRIPTION
Restore-Subscription 関数は、$Script:originalSubscription 変数に保存されているサブスクリプションを現在のサブスクリプションに (もう一度) 設定します。元のサブスクリプションにストレージ アカウントがある場合、この関数はストレージ アカウントを現在のサブスクリプションに対する現在のストレージ アカウントに設定します。この関数は、環境内に null ではない $SubscriptionName 変数が存在している場合にのみ、サブスクリプションを復元します。それ以外の場合は、終了します。$SubscriptionName に値が設定されていても $Script:originalSubscription が $null の場合、Restore-Subscription は Select-AzureSubscription コマンドレットを使用して、Microsoft Azure PowerShell でのサブスクリプションの現在および既定の設定をクリアします。この関数にパラメーターはなく、入力を受け取りません。また、何も返しません (void を返します)。-Verbose を使用すると、メッセージを Verbose ストリームに書き込むことができます。

.INPUTS
なし

.OUTPUTS
なし

.EXAMPLE
PS C:\> Restore-Subscription
PS C:\>

.EXAMPLE
PS C:\> Restore-Subscription -Verbose
VERBOSE: Restore-Subscription: Start
VERBOSE: Restore-Subscription: End
#>
function Restore-Subscription
{
    [CmdletBinding()]
    param()

    Write-VerboseWithTime 'Restore-Subscription: 開始'

    if ($Script:originalCurrentSubscription)
    {
        if ($Script:originalCurrentStorageAccount)
        {
            Set-AzureSubscription `
                -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName `
                -CurrentStorageAccountName $Script:originalCurrentStorageAccount
        }

        Select-AzureSubscription -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName
    }
    else 
    {
        Select-AzureSubscription -NoCurrent
        Select-AzureSubscription -NoDefault
    }
    
    if ($Script:userSpecifiedSubscription -and $Script:originalStorageAccountOfUserSpecifiedSubscription)
    {
        Set-AzureSubscription `
            -SubscriptionName $Script:userSpecifiedSubscription `
            -CurrentStorageAccountName $Script:originalStorageAccountOfUserSpecifiedSubscription
    }

    Write-VerboseWithTime 'Restore-Subscription: 終了'
}


<#
.SYNOPSIS
構成ファイルを検証し、構成ファイル値のハッシュ テーブルを返します。

.DESCRIPTION
Read-ConfigFile 関数は、JSON 構成ファイルを検証し、選択された値のハッシュ テーブルを返します。
-- JSON ファイルの PSCustomObject への変換によって始まります。Web サイトのハッシュ テーブルには次のキーが含まれます。
-- Location: Web サイトの場所
-- Databases: Web サイトの SQL データベース

.PARAMETER  ConfigurationFile
Web プロジェクト用 JSON 構成ファイルのパスと名前を指定します。Web プロジェクトの作成時に Visual Studio によって JSON ファイルが自動生成され、ソリューションの PublishScripts フォルダーに格納されます。

.PARAMETER HasWebDeployPackage
Web アプリケーション用の Web 配置パッケージの ZIP ファイルがあることを示します。$true の値を指定するには、-HasWebDeployPackage または HasWebDeployPackage:$true を使用します。false の値を指定するには、HasWebDeployPackage:$false を使用します。このパラメーターは必須です。

.INPUTS
なし。この関数には入力をパイプできません。

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Read-ConfigFile -ConfigurationFile <path> -HasWebDeployPackage


Name                           Value                                                                                                                                                                     
----                           -----                                                                                                                                                                     
databases                      {@{connectionStringName=; databaseName=; serverName=; user=; password=}}                                                                                                  
website                        @{name="mysite"; location="West US";}                                                      
#>
function Read-ConfigFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $ConfigurationFile
    )

    Write-VerboseWithTime 'Read-ConfigFile: 開始'

    # JSON ファイルの内容を取得し (-raw は改行を無視します)、PSCustomObject に変換します
    $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json

    if (!$config)
    {
        throw ('Read-ConfigFile: ConvertFrom-Json が失敗しました: ' + $error[0])
    }

    # environmentSettings オブジェクトに 'webSite' プロパティがあるかどうかを確認してください (プロパティ値は関係ありません)
    $hasWebsiteProperty =  Test-Member -Object $config.environmentSettings -Member 'webSite'

    if (!$hasWebsiteProperty)
    {
        throw 'Read-ConfigFile: 構成ファイルには webSite プロパティは含まれません。'
    }

    # PSCustomObject の値からハッシュ テーブルを構築します
    $returnObject = New-Object -TypeName Hashtable

    $returnObject.Add('name', $config.environmentSettings.webSite.name)
    $returnObject.Add('location', $config.environmentSettings.webSite.location)

    if (Test-Member -Object $config.environmentSettings -Member 'databases')
    {
        $returnObject.Add('databases', $config.environmentSettings.databases)
    }

    Write-VerboseWithTime 'Read-ConfigFile: 終了'

    return $returnObject
}


<#
.SYNOPSIS
Microsoft Azure Web サイトを作成します。

.DESCRIPTION
特定の名前と場所が指定された Microsoft Azure Web サイトを作成します。この関数は Azure モジュールで New-AzureWebsite コマンドレットを呼び出します。サブスクリプションに名前が指定された Web サイトがない場合、この関数は Web サイトを作成し、Web サイト オブジェクトを返します。名前が指定された Web サイトがある場合は、既存の Web サイトを返します。

.PARAMETER  Name
新しい Web サイトの名前を指定します。名前は Microsoft Azure 内で一意である必要があります。このパラメーターは必須です。

.PARAMETER  Location
Web サイトの場所を指定します。有効な値は、"West US" などの Microsoft Azure の場所です。このパラメーターは必須です。

.INPUTS
なし。

.OUTPUTS
Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.Site

.EXAMPLE
Add-AzureWebsite -Name TestSite -Location "West US"

Name       : contoso
State      : Running
Host Names : contoso.azurewebsites.net

.LINK
New-AzureWebsite
#>
function Add-AzureWebsite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Location
    )

    Write-VerboseWithTime 'Add-AzureWebsite: 開始'
    $website = Get-AzureWebsite -Name $Name -ErrorAction SilentlyContinue

    if ($website)
    {
        Write-HostWithTime ('Add-AzureWebsite: 既存の Web サイト' +
        $website.Name + ' が見つかりました')
    }
    else
    {
        if (Test-AzureName -Website -Name $Name)
        {
            Write-ErrorWithTime ('Web サイト {0} は既に存在します' -f $Name)
        }
        else
        {
            $website = New-AzureWebsite -Name $Name -Location $Location
        }
    }

    $website | Out-String | Write-VerboseWithTime
    Write-VerboseWithTime 'Add-AzureWebsite: 終了'

    return $website
}

<#
.SYNOPSIS
URL が絶対で、その方式が https の場合は、$True を返します。

.DESCRIPTION
Test-HttpsUrl 関数は、入力 URL を System.Uri オブジェクトに変換します。URL が (相対ではなく) 絶対で、その方式が https の場合は、$True を返します。いずれかの条件が false の場合、または入力文字列を URL に変換できない場合、関数は $false を返します。

.PARAMETER Url
テストする URL を指定します。URL 文字列を入力します

.INPUTS
なし。

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\>$profile.publishUrl
waws-prod-bay-001.publish.azurewebsites.windows.net:443

PS C:\>Test-HttpsUrl -Url 'waws-prod-bay-001.publish.azurewebsites.windows.net:443'
False
#>
function Test-HttpsUrl
{

    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Url
    )

    # $uri を System.Uri オブジェクトに変換できない場合、Test-HttpsUrl は $false を返します
    $uri = $Url -as [System.Uri]

    return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
}


<#
.SYNOPSIS
Microsoft Azure SQL データベースに接続できる文字列を作成します。

.DESCRIPTION
Get-AzureSQLDatabaseConnectionString 関数は、Microsoft Azure SQL データベースに接続するための接続文字列を構築します。

.PARAMETER  DatabaseServerName
Microsoft Azure サブスクリプションの既存のデータベース サーバーの名前を指定します。すべての Microsoft Azure SQL データベースは、SQL データベース サーバーに関連付けられている必要があります。サーバー名を取得するには、Get-AzureSqlDatabaseServer コマンドレット (Azure モジュール) を使用します。このパラメーターは必須です。

.PARAMETER  DatabaseName
SQL データベースの名前を指定します。既存の SQL データベースを指定することも、新しい SQL データベースに使用する名前を指定することもできます。このパラメーターは必須です。

.PARAMETER  Username
SQL データベース管理者の名前を指定します。ユーザー名は $Username@DatabaseServerName になります。このパラメーターは必須です。

.PARAMETER  Password
SQL データベース管理者のパスワードを指定します。パスワードはプレーンテキスト形式で入力します。セキュリティで保護された文字列は使用できません。このパラメーターは必須です。

.INPUTS
なし。

.OUTPUTS
System.String

.EXAMPLE
PS C:\> $ServerName = (Get-AzureSqlDatabaseServer).ServerName[0]
PS C:\> Get-AzureSQLDatabaseConnectionString -DatabaseServerName $ServerName `
        -DatabaseName 'testdb' -UserName 'admin'  -Password 'password'

Server=tcp:testserver.database.windows.net,1433;Database=testdb;User ID=admin@testserver;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
#>
function Get-AzureSQLDatabaseConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password
    )

    return ('Server=tcp:{0}.database.windows.net,1433;Database={1};' +
           'User ID={2}@{0};' +
           'Password={3};' +
           'Trusted_Connection=False;' +
           'Encrypt=True;' +
           'Connection Timeout=20;') `
           -f $DatabaseServerName, $DatabaseName, $UserName, $Password
}


<#
.SYNOPSIS
Visual Studio によって生成される JSON 構成ファイルの値から、Microsoft Azure SQL データベースを作成します。

.DESCRIPTION
Add-AzureSQLDatabases 関数は、JSON ファイルのデータベース セクションから情報を取得します。この Add-AzureSQLDatabases 関数 (複数形) は、JSON ファイル内で SQL データベースごとに Add-AzureSQLDatabase (単数形) 関数を呼び出します。Add-AzureSQLDatabase (単数形) は New-AzureSqlDatabase コマンドレット (Azure モジュール) を呼び出し、このコマンドレットが SQL データベースを作成します。この関数はデータベース オブジェクトを返しません。データベースの作成に使用した値のハッシュ テーブルを返します。

.PARAMETER DatabaseConfig
JSON ファイルに Web サイト プロパティが含まれている場合に Read-ConfigFile 関数が返す、JSON ファイルから取得した PSCustomObjects の配列を受け取ります。これには environmentSettings.databases プロパティが含まれます。リストをこの関数にパイプできます。
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig
connectionStringName: Default Connection
databasename : TestDB1
edition   :
size     : 1
collation  : SQL_Latin1_General_CP1_CI_AS
servertype  : New SQL Database Server
servername  : r040tvt2gx
user     : dbuser
password   : Test.123
location   : West US

.PARAMETER  DatabaseServerPassword
SQL データベース サーバー管理者のパスワードを指定します。Name キーと Password キーを含むハッシュテーブルを入力してください。Name の値は、SQL データベース サーバーの名前です。Password の値は、管理者パスワードです。例: @Name = "TestDB1"; Password = "password" このパラメーターはオプションです。このパラメーターを省略するか、SQL データベース サーバー名が $DatabaseConfig オブジェクトの serverName プロパティの値に一致しない場合、関数では接続文字列の SQL データベースに対して $DatabaseConfig オブジェクトの Password プロパティを使用します。

.PARAMETER CreateDatabase
データベースを作成するかどうかを検証します。このパラメーターは省略可能です。

.INPUTS
System.Collections.Hashtable[]

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig | Add-AzureSQLDatabases

Name                           Value
----                           -----
ConnectionString               Server=tcp:testdb1.database.windows.net,1433;Database=testdb;User ID=admin@testdb1;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
Name                           Default Connection
Type                           SQLAzure

.LINK
Get-AzureSQLDatabaseConnectionString

.LINK
Create-AzureSQLDatabase
#>
function Add-AzureSQLDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $DatabaseConfig,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword,

        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateDatabase = $false
    )

    begin
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: 開始'
    }
    process
    {
        Write-VerboseWithTime ('Add-AzureSQLDatabases: 作成しています: ' + $DatabaseConfig.databaseName)

        if ($CreateDatabase)
        {
            # DatabaseConfig 値で新しい SQL データベースを作成します (まだデータベースが存在しない場合)
            # コマンド出力は表示されません。
            Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig | Out-Null
        }

        $serverPassword = $null
        if ($DatabaseServerPassword)
        {
            foreach ($credential in $DatabaseServerPassword)
            {
               if ($credential.Name -eq $DatabaseConfig.serverName)
               {
                   $serverPassword = $credential.password             
                   break
               }
            }               
        }

        if (!$serverPassword)
        {
            $serverPassword = $DatabaseConfig.password
        }

        return @{
            Name = $DatabaseConfig.connectionStringName;
            Type = 'SQLAzure';
            ConnectionString = Get-AzureSQLDatabaseConnectionString `
                -DatabaseServerName $DatabaseConfig.serverName `
                -DatabaseName $DatabaseConfig.databaseName `
                -UserName $DatabaseConfig.user `
                -Password $serverPassword }
    }
    end
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: 終了'
    }
}


<#
.SYNOPSIS
新しい Microsoft Azure SQL データベースを作成します。

.DESCRIPTION
Add-AzureSQLDatabase 関数は、Visual Studio によって生成される JSON 構成ファイル内のデータから Microsoft Azure SQL データベースを作成し、新しいデータベースを返します。指定されたデータベース名の SQL データベースを既にサブスクリプションが指定された SQL データベース サーバー内に持っている場合、関数は既存のデータベースを返します。この関数は New-AzureSqlDatabase コマンドレット (Azure モジュール) を呼び出し、このコマンドレットが実際に SQL データベースを作成します。

.PARAMETER DatabaseConfig
JSON ファイルに Web サイト プロパティが含まれている場合に Read-ConfigFile 関数が返す、JSON 構成ファイルから取得した PSCustomObject を受け取ります。これには environmentSettings.databases プロパティが含まれます。この関数にはオブジェクトをパイプできません。Visual Studio によって、すべての Web プロジェクト用に JSON 構成ファイルが生成され、ソリューションの PublishScripts フォルダーに格納されます。

.INPUTS
なし。この関数はパイプラインからの入力を受け取りません

.OUTPUTS
Microsoft.WindowsAzure.Commands.SqlDatabase.Services.Server.Database

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases | where connectionStringName
PS C:\> $DatabaseConfig

connectionStringName    : Default Connection
databasename : TestDB1
edition      :
size         : 1
collation    : SQL_Latin1_General_CP1_CI_AS
servertype   : New SQL Database Server
servername   : r040tvt2gx
user         : dbuser
password     : Test.123
location     : West US

PS C:\> Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig

.LINK
Add-AzureSQLDatabases

.LINK
New-AzureSQLDatabase
#>
function Add-AzureSQLDatabase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Object]
        $DatabaseConfig
    )

    Write-VerboseWithTime 'Add-AzureSQLDatabase: 開始'

    # パラメーター値にサーバー名プロパティが含まれていない場合、またはサーバー名プロパティの値が設定されていない場合は、失敗します。
    if (-not (Test-Member $DatabaseConfig 'serverName') -or -not $DatabaseConfig.serverName)
    {
        throw 'Add-AzureSQLDatabase: データベース サーバー名 (必須) が DatabaseConfig 値にありません。'
    }

    # パラメーター値にデータベース名プロパティが含まれていない場合、またはデータベース名プロパティの値が設定されていない場合は、失敗します。
    if (-not (Test-Member $DatabaseConfig 'databaseName') -or -not $DatabaseConfig.databaseName)
    {
        throw 'Add-AzureSQLDatabase: データベース名 (必須) が DatabaseConfig 値にありません。'
    }

    $DbServer = $null

    if (Test-HttpsUrl $DatabaseConfig.serverName)
    {
        $absoluteDbServer = $DatabaseConfig.serverName -as [System.Uri]
        $subscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

        if ($subscription -and $subscription.ServiceEndpoint -and $subscription.SubscriptionId)
        {
            $absoluteDbServerRegex = 'https:\/\/{0}\/{1}\/services\/sqlservers\/servers\/(.+)\.database\.windows\.net\/databases' -f `
                                     $subscription.serviceEndpoint.Host, $subscription.SubscriptionId

            if ($absoluteDbServer -match $absoluteDbServerRegex -and $Matches.Count -eq 2)
            {
                 $DbServer = $Matches[1]
            }
        }
    }

    if (!$DbServer)
    {
        $DbServer = $DatabaseConfig.serverName
    }

    $db = Get-AzureSqlDatabase -ServerName $DbServer -DatabaseName $DatabaseConfig.databaseName -ErrorAction SilentlyContinue

    if ($db)
    {
        Write-HostWithTime ('Create-AzureSQLDatabase: 既存のデータベースを使用しています: ' + $db.Name)
        $db | Out-String | Write-VerboseWithTime
    }
    else
    {
        $param = New-Object -TypeName Hashtable
        $param.Add('serverName', $DbServer)
        $param.Add('databaseName', $DatabaseConfig.databaseName)

        if ((Test-Member $DatabaseConfig 'size') -and $DatabaseConfig.size)
        {
            $param.Add('MaxSizeGB', $DatabaseConfig.size)
        }
        else
        {
            $param.Add('MaxSizeGB', 1)
        }

        # $DatabaseConfig オブジェクトに照合順序プロパティがあり、プロパティ値が null または空ではない場合
        if ((Test-Member $DatabaseConfig 'collation') -and $DatabaseConfig.collation)
        {
            $param.Add('Collation', $DatabaseConfig.collation)
        }

        # $DatabaseConfig オブジェクトにエディション プロパティがあり、プロパティ値が null または空ではない場合
        if ((Test-Member $DatabaseConfig 'edition') -and $DatabaseConfig.edition)
        {
            $param.Add('Edition', $DatabaseConfig.edition)
        }

        # 詳細ストリームにハッシュ テーブルを書き込みます
        $param | Out-String | Write-VerboseWithTime
        # スプラッティングを使用して New-AzureSqlDatabase を呼び出します (出力は表示されません)
        $db = New-AzureSqlDatabase @param
    }

    Write-VerboseWithTime 'Add-AzureSQLDatabase: 終了'
    return $db
}
