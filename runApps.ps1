$upServer = 'cd server && npm test'
$apps_servidor = @(
    'node'
    'electron'
)
$apps_socketio = @(
    'TouchDesigner'
)


Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class SFW {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

$Flamas = [System.Convert]::toInt32("1F525",16)
$Warning = [System.Convert]::toInt32("26a0",16)
$Check_Mark = [System.Convert]::toInt32("2713",16)
$lupa = [System.Convert]::toInt32("1F50E",16)


$Emoticons = @(
    [System.Char]::ConvertFromUtf32($Flamas)
    [System.Char]::ConvertFromUtf32($Warning)
    [System.Char]::ConvertFromUtf32($Check_Mark)
    [System.Char]::ConvertFromUtf32($lupa)
)
for ($i = 0; $i -lt 3; $i++){
    $flama_repeat +=  @($Emoticons[0])
    $warning_repeat +=  @($Emoticons[1])
    $lupa_repeat +=  @($Emoticons[3])
}

function up_servidor{
    $lista_PID = @()
  
    Write-Host $warning_repeat '<<<<<< UP servidor >>>>>>' $warning_repeat -BackgroundColor DarkGreen
    $msg = Start-Process cmd.exe -ArgumentList "/c ($upServer)" -PassThru -WindowStyle Minimized
    
    $status_port = 0

    while($status_port -ne 1){
        $proceso = Get-Process -Name $apps_servidor -ErrorAction Ignore
        $port_activo = 0

        foreach ($i in $proceso){
            $status_puerto = Netstat -ano | findstr $i.ID

            if($status_puerto){
                Write-Host  'PID_OPEN: ' $i.ID $i.Name $Emoticons[2] -BackgroundColor DarkBlue
                $lista_PID += @($i.ID)
                #Aqui por lo que andamos eligiendo 2 es que se estan abriendo dos procesos de Electron
                #al parecer uno corresponde al de la terminal y el otro a la app
                if($lista_PID.Length -cge 2){
                    $port_activo = 1
                }
            }else{
                Write-Host  'PID: ' $i.ID $i.Name
                $lista_PID += @($i.ID) 
            }
        }

        if($port_activo -eq 1){
            Write-Host $flama_repeat " <<<<<< SERVIDOR OK!! >>>>>>>" $flama_repeat  -BackgroundColor DarkRed
            $status_port = 1
      
        }else {
            $lista_PID = @()
            Start-Sleep 3
        }
    }
    return $lista_PID

}

function open_TouchDesigner{
    Start-Process -FilePath ".\clienteTouch\app.toe" 
    
    $i = 0
    $find_puerto = 0
    while($i -ne 1){
        $procesos = Get-Process -Name $apps_socketio -ErrorAction Ignore
        if($procesos){
            Write-Host 'TOUCH se esta abriendo ... ' $Emoticons[2] -BackgroundColor DarkBlue
            foreach($x in $procesos){
                $PID_ += @($procesos.Id)
                Write-Host $lupa_repeat 'Buscando puerto abierto: '$procesos.Name $procesos.Id $lupa_repeat -BackgroundColor DarkGreen
                while($find_puerto -ne 1){
                    $status_puerto = Netstat -ano | findstr $procesos.Id
                    if($status_puerto){
                        Write-Host $flama_repeat 'Se establecio conexion con Touch' $flama_repeat -BackgroundColor DarkRed
                        $find_puerto = 1
                    }else{
                        Write-Host $warning_repeat 'No hay conexion con Touch' $warning_repeat
                        Start-Sleep 2
                    }
                 }
            }
            $i = 1
        }else{
            Write-Host 'No esta Abierta la App'
            Start-Sleep 2
        }
    }

    $seguro = 'False'
    while($seguro -ne 'True'){
    Write-Host $lupa_repeat 'buscando ventana TOUCHDESIGNER' $lupa_repeat -BackgroundColor DarkGreen
        
    foreach($i in $PID_){
    $h =  (Get-Process -Id $i).MainWindowHandle # just one notepad must be opened!
        
    if([SFW]::SetForegroundWindow($h)){
        $seguro = 'True'
        Write-Host 'Ventana TOUCHDESIGNER' $Emoticons[2] -BackgroundColor DarkBlue
        }
    }
    Start-Sleep 2
    }

    return $PID_
}

"function Close_All($PIDS){
    Write-Host  $flama_repeat '<<<<<< Cerrando Procesos... >>>>>>>' $flama_repeat  -BackgroundColor DarkRed
    
    foreach($i in $PIDS){
        Write-Host $warning_repeat 'CLOSING...' $msg  'PID: ' $i $warning_repeat
        $msg = Stop-Process -Id $i -Force -PassThru -ErrorAction Ignore
        
    }
}"

Try
{
    $PID_servidor =  up_servidor

    if ($PID_servidor){
        $PID_TouchDesigner = open_TouchDesigner
        $seguro = 'False'
        while($seguro -ne 'True'){
            Write-Host $lupa_repeat 'buscando ventana ELECTRON' $lupa_repeat -BackgroundColor DarkGreen
            foreach($i in $PID_servidor){
                $h =  (Get-Process -Id $i).MainWindowHandle # just one notepad must be opened!
                if([SFW]::SetForegroundWindow($h)){
                    #OJO con esto hay que quitar esta variable por si queremos colocar 
                    #esto en un loop infinito y que cada cierto tiempo la ventana se force a este enfrente
                    $seguro = 'True'
                    Write-Host 'Ventana ELECTRON' $Emoticons[2] -BackgroundColor DarkBlue
                }
            }
            Start-Sleep 2
        }

        Read-Host "Presiona ENTER para cerrar TODO"
        $PID_CLOSE = @(
            $PID_servidor
            $PID_TouchDesigner
        )
        Close_All($PID_CLOSE)
    }else{
        Write-Host 'No se ha levantado el servidor' -BackgroundColor DarkRed
        Write-Host 'Tal vez la ruta esta fallando o la escribiste mal' -BackgroundColor DarkRed
    }
    

}catch [System.Exception]
{
    Close_All($PID_servidor)
    Write-Output 'Algo salio mal'

}


