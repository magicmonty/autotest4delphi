Autotest 4 Delphi README
===

This is a little project for making Continuous Testing possible with Delphi.

The code was written with BDS 2006 but should work with later versions too.

In Order to work with this tool, you need the following:

* a test project
* Growl for Windows (optional)
* Delphi (BDS 2006 or higher)
* a file named `autotest.ini` in the same directory as the autotest4delphi.exe

The Test-Project
---

The test project MUST return an non zero Error code if there is a failure.
An example project lies in the examples directory.
I usually replace the ConsoleTestRunner with a modified XMLTestRunner, which
outputs a NUnit compatible XML. 
I took the XMLTestRunner from [DelphiXtreme](http://http://delphixtreme.com/wordpress/?page_id=8)
for this task.


The Test procject will be compiled with 

`<dcc32.exe> -CC -DCONSOLE_TESTRUNNER;TEST;AUTOTEST -E<path of testproject>\bin -N0<path of testproject>\dcu -Q <testproject>`

I usually place a `dcc32.cfg` with references to the matching library dirs in the test project to get it to compile

The Ini-File
---

The Ini-File is a simple text file named `autotest.ini`.
It must consist of a section [autotest] and has three entries:

* **TestProject** - This is the path to the .dpr-File with the DUnit-Test project
* **DirectoryToWatch** - This is the directory which will be watched for changes. All subdirectories will be watched too.
* **DCC32Exe** - This is the path to the dcc32.exe for compiling the test project.

for example:

    [section]
    TestProject=C:\Projects\MyAwesomeProject\Tests\MyAwesomeProjectTests.dpr
    DirectoryToWatch=C:\Projects\MyAwesomeProject
    DirectoryToWatch=C:\Program Files (x86)\Borland\BDS\4.0\bin\dcc32.exe


P.S.:

I apologize for not having done TDD for this project ;)
