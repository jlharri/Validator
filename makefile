

DIR = validator.lrplugin

SOURCES = AcceptHashes.lua \
	AutoUpdate.lua \
	ClearHashes.lua \
	Common.lua \
	GenerateHashes.lua \
	HashFunctions.lua \
	Help.lua \
	Info.lua \
	MetadataDefinitionFile.lua \
	MetadataTagset.lua \
	PluginInfoProvider.lua \
	PluginInit.lua \
	PluginManager.lua \
	VerifyImages.lua

all: $(SOURCES) TranslatedStrings_en.txt


$(SOURCES): 
	luac -s -o $(DIR)/$@ src/$@

TranslatedStrings_en.txt:
	cp src/$@ $(DIR)



