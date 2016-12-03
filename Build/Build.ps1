
# All this script does is copy some stuff from my own profile to this project directory and strip them of any signatures.
Copy-Item -Path $ProfileDir\Scripts\*.ps1 -Destination ..\Scripts -Force
Copy-Item -Path $ProfileDir\Data\quotes.txt -Destination ..\Data\quotes.txt -Force
Copy-Item -Path $ProfileDir\Modules\Environment\Environment.psm1 -Destination ..\Modules\Environment\Environment.psm1 -Force
Copy-Item -Path $ProfileDir\Microsoft.PowerShell_profile.ps1 -Destination ..\Microsoft.PowerShell_profile.ps1 -Force
UnsignAllScripts.ps1 -Path '..\'