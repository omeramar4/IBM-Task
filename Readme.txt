How to run the web app:

1. Extract all of the files

2. Run the "MyDatabase.sql" file. Look at lines 7 and 9, change the path according to the sql server installed on your computer.

3. Open DrawPad.sln in Visual Studio. The application is under "DrawingBoard.aspx".

4. Open "DrawingBoard.aspx.cs"

5. Change the constant "connStr" to the connection string of you sql server. The constant is currently Server=localhost\SQLEXPRESS;Database=master;Trusted_Connection=True;

6. Change the constant "txtPath" to the path of the folder in your computer. The txt file is at DrawPad/DrawPad/IsPrivate.txt.

7. Press Run.

***NOTICE: See the report file explaining how to use the app and the design process in order to use the web app right*** 


