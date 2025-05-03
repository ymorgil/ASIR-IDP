Import-Module ActiveDirectory 

# Obtener ruta base del script, compatible con ISE y ejecución directa
if ($PSScriptRoot) {
    $basePath = $PSScriptRoot
}
elseif ($PSCommandPath) {
    $basePath = Split-Path -Path $PSCommandPath -Parent
}
else {
    $basePath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}

# Rutas relativas a la carpeta CSV
$paisesPath = Join-Path $basePath "paises.csv"
$usuariosPath = Join-Path $basePath "Usuarios.csv"

# Variable global para el diccionario de países
$global:DiccionarioPaises = @{}

# Cargar archivo de países y construir el diccionario
function Cargar-Paises {
    if (-not (Test-Path $paisesPath)) {
        Write-Host "Archivo de países no encontrado en: $paisesPath"
        return
    }

    $paises = Import-Csv -Path $paisesPath
    foreach ($pais in $paises) {
        $nombreIngles = $pais.name.Trim()
        $iso2 = $pais.iso2.Trim()
        if ($nombreIngles -and $iso2) {
            $global:DiccionarioPaises[$nombreIngles.ToLower()] = $iso2
        }
    }

    Write-Host "Diccionario de países cargado correctamente."
}

# Convertir nombre de país a código ISO2
function Obtener-CodigoISO2 {
    param([string]$nombrePais)

    $clave = $nombrePais.Trim().ToLower()
    if ($global:DiccionarioPaises.ContainsKey($clave)) {
        return $global:DiccionarioPaises[$clave]
    }
    else {
        Write-Host "No se encontró el código ISO para el país: $nombrePais"
        return ""
    }
}

# Agrega la UO si no existe
function Agregar-UO {
    $global:ouNombre = "appnube"
    $global:dominio = (Get-ADDomain).DistinguishedName
    $global:ouPath = "OU=$ouNombre,$dominio"

    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouNombre'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ouNombre -Path $dominio
        Write-Host "Unidad Organizativa '$ouNombre' creada correctamente."
    }
    else {
        Write-Host "La UO '$ouNombre' ya existe."
    }
}

# Función para agregar un usuario al AD
function Agregar-Usuario {
    param (
        [string]$usuario,
        [string]$contrasenaTexto,
        [string]$nombre,
        [string]$apellidos,
        [string]$email,
        [string]$pais,
        [string]$grupo
    )

    try {
        $securePassword = ConvertTo-SecureString $contrasenaTexto -AsPlainText -Force
        $nombreCompleto = "$nombre $apellidos"
        $samAccountName = $usuario
        $userPrincipalName = "$usuario@$((Get-ADDomain).DnsRoot)"
        $codigoISO = Obtener-CodigoISO2 -nombrePais $pais

        if (-not $codigoISO) {
            Write-Host "Saltando usuario '$usuario' por país no válido."
            return
        }

        if (-not (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue)) {
            New-ADUser `
                -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -Name $nombreCompleto `
                -GivenName $nombre `
                -Surname $apellidos `
                -EmailAddress $email `
                -Country $codigoISO `
                -AccountPassword $securePassword `
                -Enabled $true `
                -Path $global:ouPath

            Write-Host "Usuario '$usuario' creado correctamente."
        }
        else {
            Write-Host "El usuario '$usuario' ya existe."
        }

        # Verificar o crear el grupo
        if (-not (Get-ADGroup -Filter "Name -eq '$grupo'" -SearchBase $global:ouPath)) {
            New-ADGroup -Name $grupo -GroupScope Global -Path $global:ouPath
            Write-Host "Grupo '$grupo' creado."
        }

        # Agregar el usuario al grupo
        Add-ADGroupMember -Identity $grupo -Members $usuario -ErrorAction SilentlyContinue
        Write-Host "Usuario '$usuario' añadido al grupo '$grupo'."
    }
    catch {
        Write-Host "Error al crear el usuario o agregar al grupo: $_"
    }
}

# Función para cargar usuarios desde el CSV
function Cargar-Desde-CSV {
    if (-not (Test-Path $usuariosPath)) {
        Write-Host "Archivo CSV no encontrado en: $usuariosPath"
        return
    }

    $datos = Import-Csv -Path $usuariosPath

    foreach ($linea in $datos) {
        $usuario = $linea.Usuario.Trim()
        $contrasena = $linea.Contraseña.Trim()
        $nombre = $linea.Nombre.Trim()
        $apellidos = $linea.Apellidos.Trim()
        $email = $linea.email.Trim()
        $pais = $linea.Pais.Trim()
        $grupo = $linea.Grupo.Trim()

        if ($usuario -and $contrasena -and $nombre -and $apellidos -and $grupo) {
            Agregar-Usuario -usuario $usuario `
                -contrasenaTexto $contrasena `
                -nombre $nombre `
                -apellidos $apellidos `
                -email $email `
                -pais $pais `
                -grupo $grupo
        }
        else {
            Write-Host "Fila incompleta o inválida: $($linea | Out-String)"
        }
    }
}

# EJECUCIÓN AUTOMÁTICA DEL SCRIPT
Cargar-Paises
Agregar-UO
Cargar-Desde-CSV
