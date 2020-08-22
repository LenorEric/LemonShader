set fromdir=C:\Users\EC\Desktop\DocBin\Program\C\LemonShader\shaders
set todir=C:\Users\EC\Desktop\RE\minecraft 1.12.2\.minecraft\shaderpacks\LemonShader Dev\shaders\
rd "%todir%" /s /q
xcopy "%fromdir%" "%todir%" /s /e