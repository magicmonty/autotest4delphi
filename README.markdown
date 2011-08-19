Autotest 4 Delphi README
===

This is a little project for making Continuous Testing possible with Delphi.

The code was written with BDS 2006 but should work with later versions too.

In Order to work with this tool, you need the following:

* a test project
* Growl for Windows
* Delphi (BDS 2006 or higher)

The test project MUST return an non zero Error code if there is a failure.
An example project lies in the examples directory.
I usually replace the ConsoleTestRunner with a modified XMLTestRunner, which
outputs a NUnit compatible XML. 
I took the XMLTestRunner from http://http://delphixtreme.com/wordpress/?page_id=8
for this task.

The PassiveViewFramework is based on the work of http://http://delphixtreme.com

The Test procject will be compiled with 
<dcc32.exe> -CC -DCONSOLE_TESTRUNNER;TEST;AUTOTEST -E<path of testproject>\bin -N0<path of testproject>\dcu -Q <testproject>
I usually place a dcc32.cfg with refernces to the matching library dirs in the test project to get it to compile

I apologize for not having done TDD for this project yet ;)
