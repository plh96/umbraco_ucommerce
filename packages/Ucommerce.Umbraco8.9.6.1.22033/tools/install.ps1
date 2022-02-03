param($installPath, $toolsPath, $package, $project)

Write-Host "installPath:" "${installPath}"
Write-Host "toolsPath:" "${toolsPath}"

Function RemoveApp($appPath) {
    $disabledAppPath = "$appPath.disabled"

    if (Test-Path $appPath) {
     Remove-Item $appPath -Recurse -Force  -confirm:$false
    }

    if (Test-Path $disabledAppPath) {
     Remove-Item $disabledAppPath -Recurse -Force -confirm:$false
    }
}

if ($project) {
	$dateTime = Get-Date -Format yyyyMMdd-HHmmss

	# Create paths and list them
	$projectPath = (Get-Item $project.Properties.Item("FullPath").Value).FullName
	$backupPath = Join-Path $projectPath "App_Data\NuGetBackup\$dateTime"
	$copyLogsPath = Join-Path $backupPath "CopyLogs"
	$webConfigSource = Join-Path $projectPath "Web.config"
	$configFolder = Join-Path $projectPath "Config"

	# Copy Ucommerce and Ucommerce_files from package to project folder
	$umbracoFolder = Join-Path $projectPath "Umbraco"
	$UcommerceFolderSource = Join-Path $installPath "UcommerceFiles\umbraco"
	robocopy $UcommerceFolderSource $umbracoFolder /is /it /e /xf UI.xml /xd "$UcommerceFolderSource\umbraco\ucommerce\apps"

	$ucommerceApps = @("Adyen",
	"Authorizedotnet",
	"Braintree",
	"Dibs",
	"EPay",
	"EWay",
	"GlobalCollect",
	"Ideal",
	"MultiSafepay",
	"Netaxept",
	"Ogone",
	"Payer",
	"PayEx",
	"PayPal",
	"Quickpay",
	"SagePay",
	"Schibsted",
	"SecureTrading",
	"WorldPay",
	"ExchangeRateAPICurrencyConversion",
	"Sanitization",
	"Ucommerce.Search.Lucene",
	"Ucommerce.Search.ElasticSearch"
	);

	foreach($app in $ucommerceApps) {
		if(Test-Path $umbracoFolder\ucommerce\apps\$app) {
			Remove-Item "$umbracoFolder\ucommerce\apps\$app" -Force -Recurse
		}
	}

	robocopy "$UcommerceFolderSource\ucommerce\apps" "$umbracoFolder\ucommerce\apps" /is /it /e

	$umbracoApp_PluginsFolder = Join-Path $projectPath "App_Plugins"
	$UcommerceApp_PluginsFolderSource = Join-Path $installPath "UcommerceFiles\App_Plugins"
	robocopy $UcommerceApp_PluginsFolderSource $umbracoApp_PluginsFolder /is /it /e

	$umbracoApp_GlobalResourcesFolder = Join-Path $projectPath "App_GlobalResources"
	$UcommerceApp_GlobalResourcesFolderSource = Join-Path $installPath "UcommerceFiles\App_GlobalResources"
	robocopy $UcommerceApp_GlobalResourcesFolderSource $umbracoApp_GlobalResourcesFolder /is /it /e

    # Remove apps (both enabled and .disabled)
    $appsDir = "$umbracoFolder\Ucommerce\Apps"
	RemoveApp "$appsDir\Catalogs" # moved to Core
	RemoveApp "$appsDir\RavenDB25"
	RemoveApp "$appsDir\RavenDB30"
    RemoveApp "$appsDir\Widgets\CatalogSearch" # removed due to Bolt

	$webConfigSource = Join-Path $projectPath "Web.config"
	$webConfig = New-Object XML
	$webConfig.Load($webConfigSource)

    # Remove old installationModule from before the grand renaming of 2020.
    $installerModule = $webConfig.SelectNodes("//system.webServer//modules//add[@name='UCommerceInstallationModule']")
    if($installerModule.Count -eq 1) {
        $installerModule[0].ParentNode.RemoveChild($installerModule[0])
    }

	$UcommerceInstallerModule = $webConfig.CreateElement('add')
	$UcommerceInstallerModule.SetAttribute('name', 'UcommerceInstallationModule')
	$UcommerceInstallerModule.SetAttribute('type', 'Ucommerce.Umbraco8.Installer.Installer, Ucommerce.Umbraco8.Installer')

	$UcommerceInstallerRemoveModule = $webConfig.CreateElement('remove')
	$UcommerceInstallerRemoveModule.SetAttribute('name', 'UcommerceInstallationModule')

	$UcommerceInstallerModuleSecond = $webConfig.CreateElement('add')
	$UcommerceInstallerModuleSecond.SetAttribute('name', 'UcommerceInstallationModule')
	$UcommerceInstallerModuleSecond.SetAttribute('type', 'Ucommerce.Umbraco8.Installer.Installer, Ucommerce.Umbraco8.Installer')

	$webConfig.configuration.'system.web'.httpModules.AppendChild($UcommerceInstallerModule);
	$webConfig.configuration.'system.webServer'.modules.AppendChild($UcommerceInstallerRemoveModule);
	$webConfig.configuration.'system.webServer'.modules.AppendChild($UcommerceInstallerModuleSecond);

	#Remove Castle.Windsor dependency in web.config to avoid conflicts doing upgrades when castle has been upgrade.
	$perRequestLifestyleModulesElements = $webConfig.SelectNodes("//system.webServer//modules//add[@name='PerRequestLifestyle']")
	if($perRequestLifestyleModulesElements.Count -eq 1){
		$webConfig.SelectNodes("//system.webServer//modules").RemoveChild($perRequestLifestyleModulesElements[0])
	}

	$perRequestLifestyleHttpModulesElement = $webConfig.SelectNodes("//system.web//httpModules//add[@name='PerRequestLifestyle']")[0]
	if($perRequestLifestyleHttpModulesElement.Count -eq 1){
		$webConfig.SelectSingleNode("//system.web//httpModules").RemoveChild($perRequestLifestyleHttpModulesElement)
	}

	$webConfig.Save($webConfigSource);
}