$apps_open = @(
    'TouchDesigner'
)
$apps_node = @(
    'node'
)
$apps_electron = @(
    'electron'
)
function check_status(){
            $portA = NETSTAT.EXE -ano | Select-String "3000"

            $app_open = Get-Process -Name $apps_open -ErrorAction Ignore
            $app_node = Get-Process -Name $apps_node -ErrorAction Ignore
            $app_electron = Get-Process -Name $apps_electron -ErrorAction Ignore

            $statusLog = New-Object -TypeName 'System.Collections.ArrayList';
            $date_hour = Get-Date -Format "dd/MM/yyyy HH:mm"
     
            if($portA){
                #Por lo cual quiere decir que el script de python funciona
                $statusLog.Add("ok")
            }else{
                $statusLog.Add("NO funciona el puerto 3000")
            }

        
            if($app_open){
                 $statusLog.Add("ok")
            } else{
                 $statusLog.Add("Touchdesigner NO esta abierto")
                 Stop-Process -Id $app_node.Id -Force -PassThru -ErrorAction Ignore
                 Stop-Process -Id $app_electron.Id -Force -PassThru -ErrorAction Ignore
            }
        
            if($app_node){
                $statusLog.Add("ok")
            } else{
                $statusLog.Add("NODE NO esta abierto")
                Stop-Process -Id $app_open.Id -Force -PassThru -ErrorAction Ignore
                Stop-Process -Id $app_electron.Id -Force -PassThru -ErrorAction Ignore
            }
       
           if($app_electron){
                $statusLog.Add("ok")
            } else{
                $statusLog.Add("Electron NO esta abierto")
                Stop-Process -Id $app_open.Id -Force -PassThru -ErrorAction Ignore
                Stop-Process -Id $app_electron.Id -Force -PassThru -ErrorAction Ignore
            }
   

            $getStatus = $statusLog | Where-Object { $_ –ne "ok" }
            #Write-Host $getStatus


            if($getStatus){
                Write-Host "Algo salio Mal"
                Add-content ".\log.txt" -value "$($statusLog) :: $($date_hour)"
                .\runStartUP.cmd
                
            }else{
                Write-Host "Todo bien"
                Add-content ".\log.txt" -value "Todo bien :: $($date_hour)" 
                Send-UDP
                
            }
  
}
function Send-UDP(){
    #ascii to hex lo que sigue significa "ok"
    [Byte[]] $powerOff = 0x6f,0x6b

    $EndPoint = "127.0.0.1"
    $Port = 2021

    $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
    $Address = [System.Net.IPAddress]::Parse($IP) 
    $EndPoints = New-Object System.Net.IPEndPoint($Address, $Port) 
    $Socket = New-Object System.Net.Sockets.UDPClient 
    $SendMessage = $Socket.Send($powerOff, $powerOff.count, $EndPoints)
    $Socket.Close() 
}

function Start-Listen() {

    do{
        $EndPoint = "127.0.0.1"
        $Port = 2020
        
        $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
        $Address = [System.Net.IPAddress]::Parse($IP) 
        $endpoint = New-Object System.Net.IPEndPoint($Address, $Port) 

        $udpclient= New-Object System.Net.Sockets.UdpClient $Port
        $content=$udpclient.Receive([ref]$endpoint)
        $mensaje = [Text.Encoding]::ASCII.GetString($content)
        $udpclient.Close()
        if($mensaje -eq "alive"){
   
            Write-Host "status"
            check_status
        
        }else{
            Write-Host "error en el mensaje"
        }
     }while(1)
     
    
} 

    
    Start-Listen

