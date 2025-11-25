/*
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "akd" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l cloudd.js -n "cloudd" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "accountsd" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "itunesstored" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "appstored" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "itunescloudd" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "amsaccountsd" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "AppleCredentialManagerDaemon" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "com.apple.sbd" -U
  sudo /Users/my_anonymous/Library/Python/3.8/bin/frida  -l akd.js -n "ProtectedCloudKeySyncing" -U
*/

var resolver = new ApiResolver('objc');
resolver.enumerateMatches('-[CTMobileEquipmentInfo *]', {
    onMatch: function(match) {
        Interceptor.attach(ptr(match.address), {
            onEnter: function(args) {
            console.log('[i] ' + match.name + ' hooked.');
            console.log('backtrace:\n' + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join('\n') + '\n');
            },
            onLeave: function(retval) {
            }
        });
        console.log('[i] ' + match.name + ' hooked.');
    },
    onComplete: function() { /* MUST NOT be omitted */ 
    }
});