Autotest 4 Delphi README
===

This is a little project for making Continuous Testing possible with Delphi.

The code was written with BDS 2006 but should work with later versions too.

In Order to work with this tool, you need the following:

* a test project
* Growl for Windows (optional)
* Delphi (BDS 2009 or higher)
* a file named `autotest.ini` in the same directory as the autotest4delphi.exe

The Test-Project
---

The test project MUST return an non zero Error code if there is a failure.
An example project lies in the examples directory.
I usually replace the ConsoleTestRunner with a modified XMLTestRunner, which
outputs a NUnit compatible XML. 
I took the XMLTestRunner from [DelphiXtreme](http://http://delphixtreme.com/wordpress/?page_id=8) for this task and modified it to 
the needs.

The Test procject will be compiled with 

`<dcc32.exe> -CC -DCONSOLE_TESTRUNNER;TEST;AUTOTEST -E<path of testproject>\bin -N0<path of testproject>\dcu -Q <testproject>`

I usually place a `dcc32.cfg` with references to the matching library dirs in the test project to get it to compile

The Ini-File
---

The Ini-File is a simple text file named `autotest.ini`.
It must consist of a section [autotest] and has the following:

* **DirectoryToWatch** (required) - This is the directory which will be watched for changes. All subdirectories will be watched too.
* **TestProject** - This is the path to the .dpr-File with the DUnit-Test project
* **DCC32Exe** - This is the path to the dcc32.exe for compiling the test project.
* **UseBuildXML** - if this is set to 1, and the entry **BuildXMLPath** exists and the file exists, then the configuration for the build and the test will be read from there
** if this is set, the settings **TestProject** and **DCC32Exe** will be ignored
* **BuildXMLPath** - this is the full path to an xml file with the configuration in it

for example:

    [autotest]
    TestProject=C:\Projects\MyAwesomeProject\Tests\MyAwesomeProjectTests.dpr
    DirectoryToWatch=C:\Projects\MyAwesomeProject
    DCC32Exe=C:\Program Files (x86)\Borland\BDS\4.0\bin\dcc32.exe

Format of the build.xmö
---
The build.xml must lie in the same folder where the test project is located.
It has the following format:

    <?xml version="1.0" encoding="UTF-8"?>
    <buildrunner>
      <environment>
        <!-- Here you can set Environment variables -->
        <BDS>%ProgramFiles%\CodeGear\RadStudio\6.0</BDS>
        <BDSCOMMONDIR />
        <FrameworkDir>%WINDIR%\Microsoft.NET\Framework64\</FrameworkDir>
        <FrameworkVersion>v2.0.50727</FrameworkVersion>
        <FrameworkSDKDir></FrameworkSDKDir>
        <Path>%FrameworkDir%%FrameworkVersion%;%FrameworkSDKDir%;%Path%</Path>
      </environment>
      <build>
        <command>msbuild.exe</command>
        <params>/nologo /verbosity:quiet /p:config=Release MyTests.dproj</params>
      </build>
      <test>
        <!-- 
          for the test command it is needed, that the full path is specified 
          %CD% is replaced with the path of the build.xml
        -->
        <command>%CD%\bin\MyTests.exe</command>
        <params></params>
      </test>
    </buildrunner>

Command line parameters
---

The autotest4delphi.exe accepts now an optional parameter with the path to the autotes.ini file.
e.g.

`autotest4delphi.exe "C:\Test Project\autotest.ini`


P.S.:

I apologize for not having done TDD for this project ;)
