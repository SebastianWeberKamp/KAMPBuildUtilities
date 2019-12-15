#!/bin/bash

#Travis working directory
travisworkingdir="/home/travis/build/"
testsdir="${travisworkingdir}SebastianWeberKamp/KAMP/tests"
featuresdir="${travisworkingdir}SebastianWeberKamp/KAMP/features"
updatesitedir="${travisworkingdir}SebastianWeberKamp/KAMP/releng/edu.kit.ipd.sdq.kamp.updatesite"

########################
#Clone every subproject#
########################
for arg; do
remotegithub="$(cut -d' ' -f 1 <<< $arg)"
localgit="${travisworkingdir}$(cut -d' ' -f 2 <<< $arg)"
echo "Cloning $remotegithub into $localgit"
git clone $remotegithub $localgit
done

########################################
#Extract the tests for every subproject#
########################################
for arg; do
localgit="${travisworkingdir}$(cut -d' ' -f 2 <<< $arg)"
for dir in $(find $localgit -mindepth 1 -maxdepth 1 -type d -path "*.tests"); do
echo "Moving $dir to $testsdir"
mv $dir $testsdir
done
done

################################################################
#Create the feature folder and feature.xml for every subproject#
################################################################
for arg; do
featurefolder="$(cut -d' ' -f 3 <<< $arg)"
featurelabel="$(cut -d' ' -f 4 <<< $arg)"
mkdir -p "${featuresdir}/${featurefolder}"
#Write the feature.xml header
cat FileStubs/FeatureHeader > "${featuresdir}/${featurefolder}/feature.xml"
#Add the feature tag
echo -n -e "<feature id=\"$featurefolder\" \n\t label=\"$featurelabel\" \n\t version=\"1.0.0.qualifier\" \n\t provider-name=\"SDQ\">\n" >> "${featuresdir}/${featurefolder}/feature.xml"
featuredir="${travisworkingdir}$(cut -d' ' -f 2 <<< $arg)"
featuredirs="$(find $featuredir -mindepth 1 -maxdepth 1 -type d)"
#Add all plugins to the feature.xml
for plugindir in $featuredirs; do
folder=$(basename "$plugindir")
if [ "$folder" != ".git" ]; then
echo -e "\t\t<plugin\n\t\tid=\"$folder\"\n\t\t download-size=\"0\"\n\t\t install-size=\"0\"\n\t\t version=\"0.0.0\"\n\t\t unpack=\"false\"/>" >> "${featuresdir}/${featurefolder}/feature.xml"
fi
done
echo -n -e "</feature>\n" >> "${featuresdir}/${featurefolder}/feature.xml"
#Print the file to check the result manually
#cat "${featuresdir}/${featurefolder}/feature.xml"
echo -n -e "bin.includes = feature.xml" > "${featuresdir}/${featurefolder}/build.properties"
done

########################################
#Create the pom.xml for the subprojects#
########################################
for arg; do
subprojectdir="${travisworkingdir}$(cut -d' ' -f 2 <<< $arg)"
subprojectdirfolders="$(find $subprojectdir -mindepth 1 -maxdepth 1 -type d)"
subprojectlabel="$(cut -d' ' -f 4 <<< $arg)"
cat FileStubs/PomHeader > ${subprojectdir}/pom.xml
echo -e "\t <modelVersion>4.0.0</modelVersion>" >> ${subprojectdir}/pom.xml
cat FileStubs/BundlesPomParent >> ${subprojectdir}/pom.xml
echo -e "\t <artifactId>bundles${subprojectlabel}</artifactId>" >> ${subprojectdir}/pom.xml
echo -e "\t <packaging>pom</packaging>" >> ${subprojectdir}/pom.xml
echo -e "\t <modules>" >> ${subprojectdir}/pom.xml
for plugindir in $subprojectdirfolders; do
folder=$(basename "$plugindir")
if [ "$folder" != ".git" ]; then
echo -e "\t\t <module>$folder</module>" >> ${subprojectdir}/pom.xml
fi
done
echo -n -e "\t </modules>" >> ${subprojectdir}/pom.xml
echo -n -e "\t </project>" >> ${subprojectdir}/pom.xml
done

############################################
#Create the category.xml for the updatesite#
############################################
cat FileStubs/CategoryHeader > ${updatesitedir}/category.xml
echo -n -e "<site>\n" >> ${updatesitedir}/category.xml
featuredirs="$(find $featuresdir -mindepth 1 -maxdepth 1 -type d)"
for featuredir in $featuredirs; do
folder=$(basename "$featuredir")
echo -n -e "\t<feature url=\"features/${folder}_1.0.0.qualifier.jar\" id=\"${folder}\" version=\"1.0.0.qualifier\">\n\t\t<category name=\"KAMP\"/>\n\t</feature>\n" >> ${updatesitedir}/category.xml
done
cat FileStubs/Category-Defs >> ${updatesitedir}/category.xml
echo -n -e "</site>\n" >> ${updatesitedir}/category.xml

##################################
#Create the pom.xml for the tests#
##################################
cat FileStubs/PomHeader > ${testsdir}/pom.xml
cat FileStubs/PomParent >> ${testsdir}/pom.xml
echo -e "\t<modelVersion>4.0.0</modelVersion>" >> ${testsdir}/pom.xml
echo -e "\t<artifactId>tests</artifactId>" >> ${testsdir}/pom.xml
echo -e "\t<packaging>pom</packaging>" >> ${testsdir}/pom.xml
echo -e "\t<modules>" >> ${testsdir}/pom.xml
testdirs="$(find $testsdir -mindepth 1 -maxdepth 1 -type d)"
for testdir in $testdirs; do
folder=$(basename "$testdir")
echo -e "\t\t<module>$folder</module>" >> ${testsdir}/pom.xml
done
echo -e "\t</modules>\n</project>" >> ${testsdir}/pom.xml

#####################################
#Create the pom.xml for the features#
#####################################
cat FileStubs/PomHeader > ${featuresdir}/pom.xml
cat FileStubs/PomParent >> ${featuresdir}/pom.xml
echo -e "\t<modelVersion>4.0.0</modelVersion>" >> ${featuresdir}/pom.xml
echo -e "\t<artifactId>features</artifactId>" >> ${featuresdir}/pom.xml
echo -e "\t<packaging>pom</packaging>" >> ${featuresdir}/pom.xml
echo -e "\t<modules>" >> ${featuresdir}/pom.xml
featuredirs="$(find $featuresdir -mindepth 1 -maxdepth 1 -type d)"
for featuredir in $featuredirs; do
folder=$(basename "$featuredir")
echo -e "\t\t<module>$folder</module>" >> ${featuresdir}/pom.xml
done
echo -e "\t</modules>\n</project>" >> ${featuresdir}/pom.xml
