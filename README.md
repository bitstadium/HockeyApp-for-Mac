## ABOUT

HockeyMac is a simple client application for Mac OS 10.6 or higher to upload 
files to HockeyApp. After the installation, you can drag & drop either .ipa
files or .xcarchive bundles to the dock or menu icon. HockeyMac will then 
open a window to enter release notes and set the download flag of the version.
The upload is shown with a progress bar and there is some minimal error handling.

## INSTALLATION

1. Download the latest version from [here](https://rink.hockeyapp.net/api/2/apps/67503a7926431872c4b6c1549f5bd6b1?format=zip).
2. Extract the .zip archive.
3. Copy HockeyApp to your Application folder.
4. Start HockeyApp.
5. If this is your first start, the app automatically shows the Preferences dialog: ![Preferences](http://f.cl.ly/items/1Z0V1l1O371O0R3f1n0R/HockeyAppStart.png)
6. You need to enter your HockeyApp API token. If you don't have one, then create one [here](https://rink.hockeyapp.net/manage/auth_tokens).
7. Close the dialog and you're ready to go.

## INTEGRATION WITH XCODE 4

1. Open your project.
2. Select Product > Edit Scheme.
3. Expand Archive.
4. Select Post-actions.
5. Click the + in the lower left corner of the right pane and select New Run Script Action.
6. Select your project for the build settings and enter the following command below:<pre>open -a HockeyApp "${ARCHIVE_PATH}"</pre>![Post-action for HockeyMac](http://f.cl.ly/items/0k0B0h1Q1z1e373k0440/XcodePostActionsForHockeyMac.png)
7. Confirm with OK.

If you now build your product with Build & Archive and the build was successful, the .xcarchive is automatically opened with HockeyMac. You can enter your release notes and then HockeyMac creates and uploads both the .ipa and the .dSYM file. Please note that you have to configure the correct provisioning profile for AdHoc distribution in the build configuration that you use for Build & Archive.

## COMMAND LINE OPTIONS

You can specify the following command line options:

* autoSubmit - the .ipa or .xcarchive will be automatically uploaded after it has been opened; you will see the progress bar, but not have the chance to specify release notes; after the upload is finished HockeyApp will be closed.
* downloadOff - the checkbox "Download" will be set to off after the file was opened.
* dsymPath - absolute path to dsym file
* identifier - upload to app with this public identifier
* ignoreExistingVersion - skip duplicate version check
* mandatoryOn - the checkbox "Set version as Mandatory" will be set to on
* notes - absolute path to release notes file
* notifyOn - the checkbox "Notify" will be set to on after the file was opened.
* onlyIPA - only for .xcarchive files; uploads only the .ipa file
* onlyDSYM - only for .xcarchive files; uploads only the .dSYM.zip file
* openNoPage - do nothing after upload was successful
* openDownloadPage - open the download page after upload was successful
* openVersionPage - open the version page after upload was successful
* setAlpha - set release type to 'alpha'
* setBeta - set release type to 'beta'
* setLive - set release type to 'live'
* tags - only allow users who are tagged by these tags to download the app (restrict downloads)
* token - use this api token instead of the one configured in settings

Please note that the command line options are passed to the app only at the first start. If the HockeyMac is already running, it will not consider any new arguments.

Example:

<pre>open -a HockeyApp MyApp.xcarchive --args autoSubmit notifyOn openDownloadPage tags=alphatesters,betatesters</pre>

HockeyMac will automatically upload MyApp.ipa and MyApp.dSYM.zip from the archive and notify all testers.

## BUGS OR QUESTIONS

If you have a problem, a question or a suggestion, please let us know via email to support@hockeyapp.net or our [support forums](http://support.hockeyapp.net). We appreciate any feedback!

## RELEASE NOTES

### Version 1.4

* Added image analysis (for iOS and OS-X), which optimizes all embedded PNG and JPG images: provides a space saving indicator and a protocol about and with the optimized images (@omichde, based on [http://wasted.werk01.de](http://wasted.werk01.de))

### Version 1.2.3

* New public release

### Version 1.2.2

* Added support for multiple DSYMs in xcarchive (Thanks @aufflick)
* Fixed an issue whenm using autosubmit (Thanks @eelco)
* Fixed a crash when CFBundleVersion isn't of type NSString in Info.plist
* Fixed a crash when window is closed before upload did finish
* Changed API endpoint for version uploads

### Version 1.2.1

* Added mandatory flag support (Thanks @joshbuhler!)
* Added dsymPath command line option (Thanks @shubhammittal!)
* Added support for uploading build which has the same version as an existing build on HockeyApp (Supported by HockeyApp since the 2.0 launch)
* Fixed an issue when helpful error details returned by an API call weren't shown

### Version 1.2

* Renamed to HockeyMac
* Using new HockeyApp icon
* Fixed an issue with special characters in CFBundleVersion
* Fixed an issue where uploading was blocked
* Fixed an issue with errors messages from server not shown
* Fixed an issue with release type menu and android builds

### Version 1.1 

* Added option to choose a distinct app version when uploading a release (Previews automatic selection too)
* Added option to restrict download to tags/groups
* Added command line option "tags"
* Added command line option "identifier"
* Added command line option "token"
* Added command line option "setAlpha"
* Fixed a problem when using autoSubmit not uploading dsyms

### Version 1.0.2 - 16/Mar/2012

* Fixed a problem where upload failed when app name contains a space.

### Version 1.0.1 - 15/Mar/2012

* Added release type "Alpha".
* Fixed bug when .xcarchive could not be uploaded when opened via File > Open.

### Version 1.0 - 05/Jan/2012

* Added comand line option "notes" to load notes from a text field
* Added drag & drop of files to the release notes text field
* Fixed behavior when zip file contained symbolic links (thanks to Nikita Zhuk!) 

### Version 1.0a9 - 01/Nov/2011

* Added popup menu to select the release type of the app
* Added command line option "setLive" to set the release type to "live"
* Added command line option "setBeta" to set the release type to "beta"
* Added popup menu to open the download or version page after the upload was successful; the last selected option is saved
* Added command line option "openNoPage" to do nothing after upload was successful
* Added command line option "openDownloadPage" to open the download page after upload was successful
* Added command line option "openVersionPage" to open the version page after upload was successful
* Fixed layout when window is resized

### Version 1.0a8 - 20/Oct/2011

* Added last selection of Textile/Markdown to user defaults
* Changed API endpoint for more stable handling of big uploads

### Version 1.0a7

_Released only internally._

### Version 1.0a6 - 09/Oct/2011

* Fixed wrong detection of iPhone apps as Mac apps.
* Changed entries in file type menu to .app.zip for Mac apps.

### Version 1.0a5 - 30/Sep/2011

* Added popup menu to upload .ipa & dSYM.zip, only .ipa or only .dSYM.zip from the .xcarchive bundle
* Added command line option “onlyIPA” to only upload the .ipa file
* Added command line option “onlyDSYM” to only upload the .dSYM.zip file
* Added handling of .apk files, i.e. you can now upload packages for Android as well
* Improved display of error message from server
* Increased timeout on HTTP connection to prevent errors on large files

### Version 1.0a4 - 21/Sep/2011

* Added checkbox to notify testers.
* Added command line option “autoSubmit” to automatically start the upload and stop HockeyApp after it was successfully completed.
* Added command line options “notifyOn” and “downloadOff” to change the default values of the corresponding check boxes.

### Version 1.0a3 - 06/Sep/2011

* Changed URL to https://rink.hockeyapp.net.
* Added "Check for Updates…" menu item to menubar icon menu.
* Added Cmd-Enter as shortcut for Upload button.
* Fixed bug when ipa contained more than one Info.plist.
* Fixed memory warning / leaks.

### Version 1.0a2 - 19/Jul/2011

* Added information about bundle identifier, version and short version to upload dialog.
* Fixed bug when executable name did include spaces.
* Fixed spelling bug on preference page.

### Version 1.0a1 - 07/Jul/2011

* Integrated QuincyKit.
* New menu bar icon.
* Refactored code for archive handling.
* Hide and show menu icon when running under Lion.

## LICENCE

### App

Copyright 2011 Codenauts UG. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

### Vendor/CNSKit

Copyright 2011 Codenauts UG. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

### Vendor/EMKeychain

Copyright (c) 2009 Extendmac, LLC. <support@extendmac.com>
 
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

### Vendor/QuincyKit

Author: Andreas Linde <mail@andreaslinde.de>

Copyright (c) 2009-2011 Andreas Linde.
All rights reserved.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

### Vendor/SBJSON

Copyright (C) 2007-2010 Stig Brautaset. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the author nor the names of its contributors may be used
  to endorse or promote products derived from this software without specific
  prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE

### Vendor/Sparkle

Copyright (c) 2006 Andy Matuschak

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

