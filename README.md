# messagErl
This project contains Erlang server & client, also Android client.
The application `messagErl` offers chat services, in a way that random user have to register to messagErl services, after that the user can create a chat rooms, or joining existing chat room.
Users within same chat room can send text and voice messages.
The main objective of this chat application, is to be able to serve ten thousands of messages and files sent through the web from one user to another through Erlang server to Erlang/Android client.

### Concurrency
As the server starts it’s work, thousands of processes are created, their job is listening to TCP sockets that connected to a port chosen by the server administrator.
All those processes connected and use `mnesia` data base tables.

### Distributivity
Thousands of Android/Erlang clients can connect to the server, each can create chat rooms and send text and voice messages.

### Data base
Mnesia is the optimal choise for data base, the reason is good support for concurrency, also the main reason for that database is it’s ability to save all data on disk and not just ram. 
If the server crashes or shuts down, user data will be safe, due to registration information is saved on disk.
To illustration the corelation between mnesia tables check `mnesia.jpg`. 

### Server safety
The server `tcp.erl` module is supervised through `gentcp.erl` and `tcpSup.erl` module, the reason is for safety and server maintenance.
If the server crashes the supervisor will try to bring the server back online.


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
