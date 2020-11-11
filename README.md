# DU-SIMPLE_DAMAGE_REPORT

A damage report system for dual universe
![image](https://raw.githubusercontent.com/Catharius/DU-SIMPLE-DAMAGE-REPORT/main/damage.png)

## How to use this script

Click on "damage_report_lua.json", copy paste the code and paste it into a programming board then :
* Link the board to your core
* Link up to 4 screens (It is not mandatory, the script will adapt if you have less than 4 screens)
  * Screen 1 will show top view
  * Screen 2 will show front view
  * Screen 3 will show side view
  * Screen 4 will show the damage report (You will need to turn the screen by 90 degres)
  
If you ship is small, the display may need some tuning, adjust the ship size with **DMGREPORT_size** in the lua parameters  
  
  
### Filters
You can use alt+1 (option1) to switch between filter modes
* **ALL** : Show all elements below 75% by default (You can adjust using the damagereport_txt_priority parameter)
* **WP & AV** : Show only weapons & avionics elements
* **AVIONICS**  : Show only avionics components (Wings, adjustors, vertical boosters, engines, fuel tanks, etc..)
* **WEAPONS** : Show only weapons

If you have less than 3 screens : You can use alt+2 (option2) to switch between views
* **TOP** : show the top view of your ship
* **FRONT** : show the front view of your ship
* **SIDE** : show the side view of your ship (The front of the ship is on the right)

You can use alt+3 (option3) to exit the script
  
### List of lua parameters
* **DMGREPORT_defaultFilter** : Set the default filter when you start the script (1 for all,2 for avionics and weapons,3 for avionics only, 4 for weapons only)
* **DMGREPORT_defaultView** : set the default view when you start the script (1 for top,2 for side and 3 for front)
* **DMGREPORT_dmg_priority** : show damaged components (3) Below 100%, (2) Below 75%, (1) Below 50%
* **DMGREPORT_disable_shortcuts** : Disable option1,option2 and option3 shortcuts if you need those for other things
* **DMGREPORT_size** : Set the size of the ship layout 
* **DMGREPORT_point_size** : Set the points size
* **DMGREPORT_dmg_refresh_rate** : damage report refresh rate every x seconds, increase the value if you have performances issues.
