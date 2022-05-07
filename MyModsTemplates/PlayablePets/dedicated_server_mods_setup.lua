--There are two functions that will install mods, ServerModSetup and ServerModCollectionSetup. Put the calls to the functions in this file and they will be executed on boot.

--ServerModSetup takes a string of a specific mod's Workshop id. It will download and install the mod to your mod directory on boot.
	--The Workshop id can be found at the end of the url to the mod's Workshop page.
	--Example: http://steamcommunity.com/sharedfiles/filedetails/?id=350811795
	--ServerModSetup("350811795")


ServerModSetup("2641805580")
ServerModSetup("2406109752")
ServerModSetup("828994749")
ServerModSetup("1848571133")

ServerModSetup("2406109752")
ServerModSetup("756552403")
ServerModSetup("1547216819")
ServerModSetup("1747701361")
ServerModSetup("678656172")
ServerModSetup("1179982849")
ServerModSetup("1203153454")
ServerModSetup("622612446")
ServerModSetup("622596425")
ServerModSetup("622471256")
ServerModSetup("1981571875")
ServerModSetup("503795626")

ServerModSetup("1852559465")



--ServerModCollectionSetup takes a string of a specific mod's Workshop id. It will download all the mods in the collection and install them to the mod directory on boot.
	--The Workshop id can be found at the end of the url to the collection's Workshop page.
	--Example: http://steamcommunity.com/sharedfiles/filedetails/?id=379114180
	--ServerModCollectionSetup("379114180")
