# messagErl
Android messaging application based on Erlang server

# Compilation - Erlang Server & Client
NOTE: for running Erlang server with random generated clients without android client, follow the steps below:
Clone and compile the repository:
```
git clone https://github.com/Maxim-CE/messagErl-Erlang-Server.git
cd messagErl-Erlang-Server
cd messagErl-Erlang-Client
erl -smp
make:all().
```
After the compilation, Erlang server can be used with android clients and erlang clients.
For runing Erlang server and random client generator ([example](https://youtu.be/s1EGwyiYqnw?t=52)):
```
tcpSup:start_link(NUMBER_OF_PROCESSES, PORT_NUMBER).
```
Open another terminal and input the following:
```
cd messagErl-Erlang-Server
cd messagErl-Erlang-Client
erl
test:startTest(PORT_NUMBER).
```
You should get simmilar statistics to `DB.jpg`.

NOTE: for runing Erlang server and Android client ([example](https://www.youtube.com/watch?v=s1EGwyiYqnw)):
```
cd messagErl-Erlang-Server
cd messagErl-Andoird-Client
```
In order to run the client through, one must have Android Studio, finished apk version not available yet.
Compile "Android" folder from this repository.
Also as a client, you must open permissions for storage and microphone in your smartphone.
After that enter the application named `messagErl` on your smarphone.
To set your own IP and PORT do as follows:
In MainActivity.java -> run() :
Change the IP and PORT in line 90 : "StaticSocket.setSocket (new Socket("132.72.104.174", 5678));"
In your android device, after installing messagERL - go to permission and allow storage + mic permissions for this app.
