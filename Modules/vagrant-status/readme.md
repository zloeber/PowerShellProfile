##Vagrant-Status

A PowerShell prompt modification that shows the basic status of [Vagrant](https://www.vagrantup.com/) machines in the current directory.

###Install Guide

1. Clone this repo
2. In PowerShell make sure that your ExecutionPolicy is Unrestricted
  * Get-ExecutionPolicy will show you current ExecutionPolicy.
  * Set-ExecutionPolicy Unrestricted will set your ExecutionPolicy to Unrestricted.
3. Run install.ps1 to install to your profile

###Prompt Explanation

   The prompt is defined in the profile.base.ps1 which will output a working directory as well as a simple/detailed vagrant status indicator depending on your choice. profile.base.ps1 has two options which can be commented in or out. Don't leave both out or in.

#### Detailed

   A basic example layout of this status is [D:0 R:1].

   The D(own) or 'poweroff/aborted in vagrant status' collects the number of machines for the current directory (vagrant environment) that are in that state. This will be colored in gray

   The R(unning) or 'running in vagrant status' collects the number of machines for the current directory (vagrant environment) that are in that state. This will be colored in green

   If there is a vagrantfile but no (D)own or (R)unning aka 'not created in vagrant status' machines you will see [-] in grey. This is to convey that there is a dormant vagrant environment in the current directory.

#### Simple

   If there is an active Vagrant machine(s) you will see [^] the ^ is colorized in green. If there is a vagrantfile and/or folder but no Vagrant machine(s) active you will see [-].

###Other Info

vagrant-status can be installed with posh-git from the following repo  [posh-git-vagrant-status](https://github.com/n00bworks/posh-git-vagrant-status)

###Based On

This project is based on the great PowerShell prompt plug-in [posh-git](https://github.com/dahlbyk/posh-git)

###Contributing

 1. Fork it
 2. Create your feature branch (git checkout -b my-new-feature)
 3. Commit your changes (git commit -am 'Add some feature')
 4. Push to the branch (git push origin my-new-feature)
 5. Create a new Pull Request
