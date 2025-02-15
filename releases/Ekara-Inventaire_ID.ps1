############################################################################################################
#                           Example of use of the EKARA API                                                #
############################################################################################################
# Swagger interface : https://api.ekara.ip-label.net/                                                      #
# To be personalized in the code before use: username / password / TOKEN                                   #
# Purpose of the script : Inventory of IDs Applications /Zones / Alters / Plannings / Parcours / workspace #
# Author : Guy Sacilotto                                                                                   #
############################################################################################################
# Last Update : 12/09/2023
# Version : 2.3

<#
Authentication :  user / password / TOKEN
Grouping : 
Restitution : HTML Page
Method call : 
- auth/login
- adm-api/clients
- adm-api/applications
- adm-api/zones 
- adm-api/alerts 
- adm-api/plannings 
- script-api/scripts 
- results-api/scenarios/status 
- adm-api/reports/schedules 
- adm-api/workspace
#>

Clear-Host

#region VARIABLES
#========================== SETTING THE VARIABLES ===============================
$error.clear()
add-type -assemblyName "Microsoft.VisualBasic"
[String]$global:Version = "2.3"
$global:API = "https://api.ekara.ip-label.net"                                                # Webservice URL
$global:UserName = ""                                                                         # EKARA Account
$global:PlainPassword = ""                                                                    # EKARA Password
$global:API_KEY = ""                                                                          # EKARA Key account

$Global:client = ""  

# Recherche le chemin du script
if ($psISE) {
    [String]$global:Path = Split-Path -Parent $psISE.CurrentFile.FullPath
    Write-Host -message "Path ISE = $Path" 
} else {
    #[String]$global:Path = split-path -parent $MyInvocation.MyCommand.Path
    [String]$global:Path = (Get-Item -Path ".\").FullName
    Write-Host -message "Path Direct = $Path"
}

[String]$global:HTMLFile = "INVENTAIRE_IDs.html"                                              # Nom du fichier HTML généré 
[String]$global:HTMLFullPath = $Path+"\"+$HTMLFile                                            # Path du fichier HTML généré
[String]$global:Currentdate = [DateTime]::Now.ToString("yyyy-MM-dd HH-mm-ss")                 # Récupère la date du jour

$global:headers = $null
$global:headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"       # Create Header
$headers.Add("Accept","application/json")                                                     # Setting Header
$headers.Add("Content-Type","application/json")                                               # Setting Header

# Authentication choice
    # 1 = Without asking for an account and password (you must configure the account and password in this script.)
    # 2 = Request the entry of an account and a password (default)
    # 3 = With API-KEY
    $global:Auth = 2
#endregion


#region Functions
Function List_Clients{
    try{
        #========================== adm-api/clients =============================
        Write-Host "-------------------------------------------------------------" -ForegroundColor green
        Write-Host "------------------- Liste tous les client  -------------------" -BackgroundColor "White" -ForegroundColor "DarkCyan"
        $uri ="$API/adm-api/clients"
        $clients = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers 
        $count = $clients.count

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        function ListIndexChanged { 
            #$label2.Text = $listbox.SelectedItems.Count
            $okButton.enabled = $True
        }

        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'List all clients'
        $form.Size = New-Object System.Drawing.Size(350,400)
        $form.StartPosition = 'CenterScreen'
        $Form.Opacity = 1.0
        $Form.TopMost = $false
        $Form.ShowIcon = $true                                              # Enable icon (upper left corner) $ true, disable icon
        #$Form.FormBorderStyle = 'Fixed3D'                                  # bloc resizing form
        
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(75,330)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Text = 'OK'
        $okButton.AutoSize = $true
        $okButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom 
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $okButton.enabled = $False
        $form.AcceptButton = $okButton

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(150,330)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.AutoSize = $true
        $cancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom 
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        
        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(10,20)
        $label.Size = New-Object System.Drawing.Size(280,20)
        $label.Text = 'Select the client to run inventory:'
        $label.AutoSize = $true
        $label.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
        -bor [System.Windows.Forms.AnchorStyles]::Bottom `
        -bor [System.Windows.Forms.AnchorStyles]::Left `
        -bor [System.Windows.Forms.AnchorStyles]::Right

        $label2 = New-Object System.Windows.Forms.Label
        $label2.Location = New-Object System.Drawing.Point(10,335)
        $label2.Size = New-Object System.Drawing.Size(20,20)
        $label2.Text = $count
        $label2.AutoSize = $true
        $label2.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom `
        -bor [System.Windows.Forms.AnchorStyles]::Left 

        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Location = New-Object System.Drawing.Point(10,40)
        $listBox.Size = New-Object System.Drawing.Size(310,20)
        $listBox.Height = 280
        $listBox.SelectionMode = 'One'
        $ListBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
        -bor [System.Windows.Forms.AnchorStyles]::Bottom `
        -bor [System.Windows.Forms.AnchorStyles]::Left `
        -bor [System.Windows.Forms.AnchorStyles]::Right

        $listboxCollection =@()

        foreach($client in $clients){
            $Object = New-Object Object 
            $Object | Add-Member -type NoteProperty -Name id -Value $client.id
            $Object | Add-Member -type NoteProperty -Name name -Value $client.name
            $listboxCollection += $Object
        }
        
        # Count selected item
        $ListBox.Add_SelectedIndexChanged({ ListIndexChanged })

        #Add collection to the $listbox
        $listBox.Items.AddRange($listboxCollection)
        $listBox.ValueMember = "$listboxCollection.id"
        $listBox.DisplayMember = "$listboxCollection.name"
        
        #Add composant into Form
        $form.Controls.Add($okButton)
        $form.Controls.Add($cancelButton)
        $form.Controls.Add($listBox)
        $form.Controls.Add($label2)
        $form.Controls.Add($label)
        $form.Topmost = $true
        $result = $form.ShowDialog()
        
        if (($result -eq [System.Windows.Forms.DialogResult]::OK) -and $listbox.SelectedItems.Count -gt 0)
        {
            Write-Host "------------------- Client sélectionné -------------------" -BackgroundColor "White" -ForegroundColor "DarkCyan"
            $ItemsName = $listBox.SelectedItems.name
            $global:ItemsID = $listBox.SelectedItems.id
            $global:clientId = $ItemsID
            Write-Host "Client name selected :$ItemsName (ID = $clientId)" -ForegroundColor Green
            
            # RUN All requests
            Create_HTML | Out-Null              # Creating a HNML file for content

            Write-Host "--> WORKSPACES list" -ForegroundColor Blue
            Inventory_Workspace $clientId

            Write-Host "--> APPLICATIONS list" -ForegroundColor Blue
            Inventory_applications $clientId

            Write-Host "--> ZONES list" -ForegroundColor Blue
            Inventory_Zones $clientId

            Write-Host "--> ALERTES list" -ForegroundColor Blue
            Inventory_Alertes $clientId
 
            Write-Host "--> PLANNINGS list" -ForegroundColor Blue
            Inventory_Planings $clientId

            Write-Host "--> PARCOURS list" -ForegroundColor Blue
            Inventory_Parcours $clientId

            Write-Host "--> SCENARIOS list" -ForegroundColor Blue
            Intentory_scenarios

            Write-Host "--> REPPORTS list" -ForegroundColor Blue
            Inventory_reports $clientId

            End_HTML | Out-Null                 # Finish the HTML file

            Write-Host ("END Client inventory ["+$ItemsName+"]: " + $Result_OK) -BackgroundColor Green

            start-Process $HTMLFullPath         # Open WEB page
        }else{
            Write-Host "Aucun client sélectionné" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(`
                "------------------------------------`n`r Aucun client sélectionné`n`r------------------------------------`n`r",`
                "Resultat",[System.Windows.Forms.MessageBoxButtons]::OKCancel,[System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
    catch{
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red

        Error_popup($Error[0])
    } 
}

function Authentication{
    try{
        Switch($Auth){
            1{
                # Without asking for an account and password
                if(($null -ne $UserName -and $null -ne $PlainPassword) -and ($UserName -ne '' -and $PlainPassword -ne '')){
                    Write-Host "--- Automatic AUTHENTICATION (account) ---------------------------" -BackgroundColor Green
                    $uri = "$API/auth/login"                                                                                                    # Webservice Methode
                    $response = Invoke-RestMethod -Uri $uri -Method POST -Verbose -Body @{ email = "$UserName"; password = "$PlainPassword"}    # Call WebService method
                    $global:Token = $response.token                                                                                             # Register the TOKEN
                    $global:headers.Add("authorization","Bearer $Token")                                                                        # Adding the TOKEN into header
                }Else{
                    Write-Host "--- Account and Password not set ! ---------------------------" -BackgroundColor Red
                    Write-Host "--- To use this connection mode, you must configure the account and password in this script." -ForegroundColor Red
                    Break Script
                }
            }
            2{
                # Requests the entry of an account and a password (default) 
                Write-Host "------------------------------ AUTHENTICATION with account entry ---------------------------" -ForegroundColor Green
                $MyAccount = $Null
                $MyAccount = Get-credential -Message "EKARA login account" -ErrorAction Stop                                            # Request entry of the EKARA Account
                if(($null -ne $MyAccount) -and ($MyAccount.password.Length -gt 0)){
                    $UserName = $MyAccount.GetNetworkCredential().username
                    $PlainPassword = $MyAccount.GetNetworkCredential().Password
                    $uri = "$API/auth/login"
                    $response = Invoke-RestMethod -Uri $uri -Method POST -Body @{ email = "$UserName"; password = "$PlainPassword"} -Verbose     # Call WebService method
                    $Token = $response.token                                                                                            # Register the TOKEN
                    $global:headers.Add("authorization","Bearer $Token")
                }Else{
                    Write-Host "--- Account and password not specified ! ---------------------------" -BackgroundColor Red
                    Write-Host "--- To use this connection mode, you must enter Account and password." -ForegroundColor Red
                    Break Script
                }
            }
            3{
                # With API-KEY
                Write-Host "------------------------------ AUTHENTICATION With API-KEY ---------------------------" -ForegroundColor Green
                if(($null -ne $API_KEY) -and ($API_KEY -ne '')){
                    $global:headers.Add("X-API-KEY", $API_KEY)
                }Else{
                    Write-Host "--- API-KEY not specified ! ---------------------------" -BackgroundColor Red
                    Write-Host "--- To use this connection mode, you must configure API-KEY." -ForegroundColor Red
                    Break Script
                }
            }
        }
    }Catch{

    Write-Host "-------------------------------------------------------------" -ForegroundColor red 
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Break Script
    }
}

function Create_HTML(){
    # Create WEB page
    Write-Host "Create WEB page" -ForegroundColor blue
    New-Item $HTMLFullPath -Type file -force
    Add-Content -Path $HTMLFullPath -Value $top
}

function Inventory_applications(){
    #========================== adm-api/applications =============================
    # Call WS : adm-api/applications
    try{
        Write-Host "/adm-api/applications" -BackgroundColor Blue                                                                  # Display information
        $uri ="$API/adm-api/applications?clientId=$clientId"                                                                                         # Webservice Methode
        $applications = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers                                                 # Call WebService method
        $applications = $applications | Sort-object -Property name
        
        $count = $applications.count
        $htmldata1 = "<hr>
                        <div>
                        <center><section><fieldset><legend>Liste $count Applications <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'applications')"">&#54</a></legend>
                          <div>
				            <div id=""applications"" style=""visibility: hidden;display: none"">
                                <table><thead><tr><th>Name</th><th>ID</th><th>Description</th></tr></thead><tbody>"


        Foreach ($application in $applications)
        {
            Write-Host "Appliction Name : " $application.name  -BackgroundColor Green                                             # Display information
            Write-Host "--> Appliction ID : " $application.id                                                                     # Display information
            Write-Host "--> Appliction Description : " $application.description                                                   # Display information

            # Generation du contenu de la page WEB
            $htmldata1 += "<tr><td>"+$application.name+"</td><td>"+$application.id+"</td><td>"+$application.description+"</td></tr>"
        }
        $htmldata1 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
        Add-Content -Path $HTMLFullPath -Value $htmldata1
    }
    catch{
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
    }                                                                      
}

function Inventory_Zones(){
    #========================== adm-api/Zones =============================
        # Call WS : adm-api/applications
        try{
            Write-Host "/adm-api/zones" -BackgroundColor Blue                                                                    # Display information
            $uri ="$API/adm-api/zones?clientId=$clientId"                                                                          # Webservice Methode
            $Zones = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers                                                   # Call WebService method
            $Zones = $Zones | Sort-object -Property name
            $count = $Zones.count
            $htmldata2 = "<hr>
                            <div>
                            <center><section><fieldset><legend>Liste $count Zones <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'Zones')"">&#54</a></legend>
                              <div>
				                <div id=""Zones"" style=""visibility: hidden;display: none"">
                                    <table><thead><tr><th>Name</th><th>ID</th><th>Description</th></tr></thead><tbody>"
            Foreach ($Zone in $Zones)
            {
                Write-Host "Zone Name : " $Zone.name  -BackgroundColor Green                                                     # Display information
                Write-Host "--> Zone ID : " $Zone.id                                                                             # Display information
                Write-Host "--> Zone Description : " $Zone.description                                                           # Display information

                # Generation du contenu de la page WEB
                $htmldata2 += "<tr><td>"+$Zone.name+"</td><td>"+$Zone.id+"</td><td>"+$Zone.description+"</td></tr>"
            }
            $htmldata2 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
            Add-Content -Path $HTMLFullPath -Value $htmldata2
        }
        catch{
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
            Write-Host "Erreur ...." -BackgroundColor Red
            Write-Host $Error.exception.Message[0]
            Write-Host $Error[0]
            Write-host $error[0].ScriptStackTrace
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
        }   
}

function Inventory_Alertes(){
    #========================== adm-api/Alerts =============================
        # Call WS : adm-api/alerts
        try{
            Write-Host "/adm-api/alerts" -BackgroundColor Blue                                                                 # Display information
            $uri ="$API/adm-api/alerts?clientId=$clientId"                                                                       # Webservice Methode
            $alerts = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers                                                # Call WebService method
            $alerts = $alerts | Sort-object -Property name
            $count = $alerts.count
            $htmldata3 = "<hr>
                            <div>
                            <center><section><fieldset><legend>Liste $count Alerts <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'Alerts')"">&#54</a></legend>
                              <div>
				                <div id=""Alerts"" style=""visibility: hidden;display: none"">
                                    <table><thead><tr><th>Name</th><th>ID</th><th>Description</th></tr></thead><tbody>"
            Foreach ($Alert in $Alerts)
            {
                Write-Host "Alert Name : " $Alert.name  -BackgroundColor Green                                                 # Display information
                Write-Host "--> Alert ID : " $Alert.id                                                                         # Display information
                Write-Host "--> Alert Description : " $Alert.description                                                       # Display information

                # Generation du contenu de la page WEB
                $htmldata3 += "<tr><td>"+$Alert.name+"</td><td>"+$Alert.id+"</td><td>"+$Alert.description+"</td></tr>"
            }
            $htmldata3 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
            Add-Content -Path $HTMLFullPath -Value $htmldata3
        }
        catch{
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
            Write-Host "Erreur ...." -BackgroundColor Red
            Write-Host $Error.exception.Message[0]
            Write-Host $Error[0]
            Write-host $error[0].ScriptStackTrace
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
        }   
}

function Inventory_Planings(){
    #========================== adm-api/Planings =============================
        # Call WS : adm-api/planings
        try{
            Write-Host "/adm-api/plannings" -BackgroundColor Blue                                                             # Display information
            $uri ="$API/adm-api/plannings?clientId=$clientId"                                                                   # Webservice Methode
            $plannings = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers                                            # Call WebService method
            $plannings = $plannings | Sort-object -Property name
            $count = $plannings.count
            $htmldata4 = "<hr>
                            <div>
                            <center><section><fieldset><legend>Liste $count plannings <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'plannings')"">&#54</a></legend>
                              <div>
				                <div id=""plannings"" style=""visibility: hidden;display: none"">
                                    <table><thead><tr><th>Name</th><th>ID</th></tr></thead><tbody>"
            Foreach ($planning in $plannings)
            {
                Write-Host "Planning Name : " $planning.name  -BackgroundColor Green                                          # Display information
                Write-Host "--> Planning ID : " $planning.id                                                                  # Display information

                # Generation du contenu de la page WEB
                $htmldata4 += "<tr><td>"+$planning.name+"</td><td>"+$planning.id+"</td></tr>"
            }
            $htmldata4 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
            Add-Content -Path $HTMLFullPath -Value $htmldata4
        }
        catch{
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
            Write-Host "Erreur ...." -BackgroundColor Red
            Write-Host $Error.exception.Message[0]
            Write-Host $Error[0]
            Write-host $error[0].ScriptStackTrace
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
        }   
}

function Inventory_Parcours(){
    #========================== adm-api/Planings =============================
        # Call WS : adm-api/planings
        try{
            Write-Host "/script-api/scripts" -BackgroundColor Blue                                                            # Display information
            $uri ="$API/script-api/scripts?clientId=$clientId"                                                                  # Webservice Methode
            $scripts = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers                                             # Call WebService method
            $scripts = $scripts | Sort-object -Property name
            $count = $scripts.message.Count
            $htmldata5 = "<hr>
                            <div>
                            <center><section><fieldset><legend>Liste $count parcours <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'scripts')"">&#54</a></legend>
                              <div>
				                <div id=""scripts"" style=""visibility: hidden;display: none"">
                                    <table><thead><tr><th>Name</th><th>ID</th><th>Description</th><th>Version</th><th>Version ID</th></tr></thead><tbody>"
            
            Foreach ($script in $scripts.message)
            {
                Write-Host "Script Name : " $script.name  -BackgroundColor Green                                     # Display information
                Write-Host "--> Script ID : " $script.id                                                             # Display information
                Write-Host "--> Script Description : " $script.description                                           # Display information

                #Recherche la dernière version de chaque parcours
                $uri= "$API/script-api/script/"+$script.id+"?clientId=$clientId"
                $scriptsVersions = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers 
                $scriptsVersions = $scriptsVersions.message.scriptversions | Select-Object -Last 1                   # Prend la dernière version
                
                Write-Host "--> Script Version : " $scriptsVersions.version                                          # Display information
                Write-Host "--> Script Version ID : " $scriptsVersions.versionId                                     # Display information
                
                # Generation du contenu de la page WEB
                #if (-not ([string]::IsNullOrEmpty($scriptsVersions.versionId))) {
                    $htmldata5 += "<tr><td>"+$script.name+"</td><td>"+$script.id+"</td><td>"+$script.description+"</td><td>"+$scriptsVersions.version+"</td><td>"+$scriptsVersions.versionId+"</td></tr>"
                #}
            }
            $htmldata5 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
            Add-Content -Path $HTMLFullPath -Value $htmldata5
        }
        catch{
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
            Write-Host "Erreur ...." -BackgroundColor Red
            Write-Host $Error.exception.Message[0]
            Write-Host $Error[0]
            Write-host $error[0].ScriptStackTrace
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
        }
}

function Intentory_scenarios{
    #========================== results-api/scenarios/status =============================
    # Call WS : results-api/scenarios/status
    try{
        Write-Host "/results-api/scenarios/status" -BackgroundColor Blue                                          # Display information
        $uri ="$API/results-api/scenarios/status?clientId=$clientId"                                              # Webservice Methode
        $scenarios = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers                                   # Call WebService method
        $scenarios = $scenarios | Sort-object -Property scenarioName
        $count = $scenarios.message.Count
        $htmldata5 = "<hr>
                        <div>
                        <center><section><fieldset><legend>Liste $count scénarios <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'scenarios')"">&#54</a></legend>
                          <div>
                            <div id=""scenarios"" style=""visibility: hidden;display: none"">
                                <table><thead><tr><th>Name</th><th>ID</th></tr></thead><tbody>"
        
        Foreach ($scenario in $scenarios)
        {
            Write-Host "Scénario Name : " $scenario.scenarioName  -BackgroundColor Green                                     # Display information
            Write-Host "--> Scénario ID : " $scenario.scenarioId                                                             # Display information

            # Generation du contenu de la page WEB
            #if (-not ([string]::IsNullOrEmpty($scriptsVersions.versionId))) {
                $htmldata5 += "<tr><td>"+$scenario.scenarioName+"</td><td>"+$scenario.scenarioId+"</td></tr>"
            #}
        }
        $htmldata5 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
        Add-Content -Path $HTMLFullPath -Value $htmldata5
    }
    catch{
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
    }
}

function Inventory_reports{
    #========================== adm-api/Planings =============================
        # Call WS : adm-api/planings
        try{
            Write-Host "/adm-api/reports/schedules" -BackgroundColor Blue                                                    # Display information
            $uri ="$API/adm-api/reports/schedules?clientId=$clientId"                                                          # Webservice Methode
            $reports = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers                                             # Call WebService method
            $reports = $reports | Sort-object -Property name
            $count = $reports.message.Count
            $htmldata5 = "<hr>
                            <div>
                            <center><section><fieldset><legend>Liste $count rapports <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'rapports')"">&#54</a></legend>
                              <div>
				                <div id=""rapports"" style=""visibility: hidden;display: none"">
                                    <table><thead><tr><th>Name</th><th>ID</th></tr></thead><tbody>"
            
            Foreach ($report in $reports)
            {
                Write-Host "Report Name : " $report.name  -BackgroundColor Green                                     # Display information
                Write-Host "--> Report ID : " $report.id                                                             # Display information
               
                # Generation du contenu de la page WEB
                #if (-not ([string]::IsNullOrEmpty($scriptsVersions.versionId))) {
                    $htmldata5 += "<tr><td>"+$report.name+"</td><td>"+$report.id+"</td></tr>"
                #}
            }
            $htmldata5 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
            Add-Content -Path $HTMLFullPath -Value $htmldata5
        }
        catch{
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
            Write-Host "Erreur ...." -BackgroundColor Red
            Write-Host $Error.exception.Message[0]
            Write-Host $Error[0]
            Write-host $error[0].ScriptStackTrace
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
        }
}

function Inventory_Workspace(){
    #========================== adm-api/workspace =============================
        # Call WS : adm-api/workspace
        try{
            Write-Host "/adm-api/workspace" -BackgroundColor Blue                                                             # Display information
            $uri ="$API/adm-api/workspaces?clientId=$clientId"                                                                  # Webservice Methode
            $workspaces = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers                                           # Call WebService method
            $workspaces = $workspaces | Sort-object -Property name
            $count = $workspaces.count
            $htmldata6 = "<hr>
                            <div>
                            <center><section><fieldset><legend>Liste $count workspaces <a class=""display"" title=""Display informations"" onClick=""DivStatus(this,'workspaces')"">&#54</a></legend>
                              <div>
				                <div id=""workspaces"" style=""visibility: hidden;display: none"">
                                    <table><thead><tr><th>Name</th><th>ID</th></tr></thead><tbody>"
            Foreach ($workspace in $workspaces)
            {
                Write-Host "Workspace Name : " $workspace.name  -BackgroundColor Green                                          # Display information
                Write-Host "--> Workspace ID : " $workspace.id                                                                  # Display information

                # Generation du contenu de la page WEB
                $htmldata6 += "<tr><td>"+$workspace.name+"</td><td>"+$workspace.id+"</td></tr>"
            }
            $htmldata6 += "</tbody><tfoot></tfoot></table></div></div></div></fieldset></center></div>"
            Add-Content -Path $HTMLFullPath -Value $htmldata6
        }
        catch{
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
            Write-Host "Erreur ...." -BackgroundColor Red
            Write-Host $Error.exception.Message[0]
            Write-Host $Error[0]
            Write-host $error[0].ScriptStackTrace
            Write-Host "-------------------------------------------------------------" -ForegroundColor red
        }   
}

function End_HTML{
    Add-Content -Path $HTMLFullPath -Value $bottom
}

#endregion

#region HTML

# Content HTML top
    [String]$global:top = @"
    <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
    <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
        <title>- Liste Applications -</title>
        <meta http-equiv='Content-type' content='text/html'>
        <style>
            html, body 
            {
	            height: 100%;
	        }

            fieldset 
            {
                font-family: sans-serif;
                background: #F2F2F2;
                border: 2px solid #D8D8D8;
                border-left : none;
                border-right : none;
                margin-top:2px;
                margin-bottom:2em;
                margin-right:0px;
                margin-left:0px;
                padding-top:15px;
                padding-bottom:20px;
                padding-right:5px;
                padding-left:5px;
            }
            fieldset legend 
            {
                background: #1F497D;
                color: #fff;
                padding: 5px 10px ;
                font-size: 30px;
                border-radius: 5px;
                box-shadow: 0 0 0 5px #ddd;
                margin-left: 20px;
            }
            section 
            {
                margin: 10px;
            }

            table
            {
                Margin: 0px 0px 0px 4px;
                Border: 1px solid rgb(190, 190, 190);
                Font-Family: Tahoma;
                Font-Size: 12pt;
                /*Background-Color: rgb(252, 252, 252);*/
                border-radius: 10px;
                box-shadow: 9px 9px 9px 9px rgba(0,0,0,0.1);
                Padding: 4px 4px 4px 4px;
                width: auto;
            }
            tr:hover td
            {
                border:1px solid #000000;
                -moz-border-radius:10px 0;
                -webkit-border-radius:10px 0;
                border-radius:10px 0;
            }
            tr:nth-child(even)
            {
                /*Background-Color: rgb(255, 243, 230);*/
		        Background-Color: rgb(252, 252, 252);
            }
	
            th
            {
                Text-Align: center;
                Color: #1F497D;
                Padding: 1px 4px 1px 4px;
            }
	
            td
            {
                Vertical-Align: Center;
                Padding: 4px 10px 4px 10px;
            }

            hr 
            {
                border: none;
                background-color: #D8D8D8;
                height: 5px;
                margin-top: 0em;
                margin-bottom: 0em;
                margin-left: 0em;
                margin-right: 0em;
            }

            section 
            {
                margin: 10px;
            }

            a.display {
	            color:white;
	            font-family: 'Webdings';
	            cursor: pointer;
            }

            h2
            {
                Background-Color: #FFFFFF;
                Font-Family: Tahoma;
                Font-Size: 10pt;
                Text-Align: center;
                color: #08298A;
            }
        </style>
        <script language="JavaScript">
            function DivStatus(image,id){
	          var Obj = document.getElementById(id);
	          var element = document.activeElement;
	  
	          if( Obj.style.visibility=="hidden")
	          {
		        // Contenu cachÃ©, le montrer
		        Obj.style.visibility ="visible";
		        Obj.style.display ="block";
		        element.blur();
		        image.title='Hide informations';
		        image.innerHTML='&#53';
	          }
	          else
	          {
		        // Contenu visible, le cacher
		        Obj.style.visibility="hidden";
		        Obj.style.display ="none";
		        element.blur();
		        image.title='Display informations';
		        image.innerHTML='&#54';
	          }
	        }
        </script>
    </head>
    <body>
"@

# Content HTML bottom
    [String]$global:bottom = @"
        </div>
        </div>
        <hr>        
        <center>
            <span id="col1">    
                <h2>Version : $Version</h2> Date : $Currentdate
            </span>
            <span id="col2">
                <h2>
                    <a href="https://ip-label.com/fr/" target="_blank">IP-LABEL</a> - <a href="https://ekara.ip-label.net/" target="_blank">EKARA</a>
                </h2>
            </span>
        </center>
    </body>
"@

#endregion


#region Main
    #========================== START SCRIPT ======================================
    Authentication
    List_Clients
#endregion
