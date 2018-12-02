using System;
using System.Data.SqlClient;
using System.Net.Sockets;
using System.Net;

namespace DrawPad
{
    public partial class DrawingBoard : System.Web.UI.Page
    {
        public static string x;     //Contains X coordinated of the drawings
        public static string y;     //Contains Y coordinated of the drawings
        public static string drag;  //Indicates if two points are continous
        public static string color; //Contains the colors of the drawings
        public static string width; //Contains the pen width of the drawings
        public static string rects; //Contains rectangles coordinates
        public static string rectsColor;    //Contains rectangles colors
        public static string paintOrRect;   //Chooses if last drawing was drawing or rectangle
        public static string isPrivate;     //Is the drawings/rectangle private or shared
        public static string ip;        //User's IP
        public static string useragent; //User's useragent
        public static string clear = "false";   //Is user pressed "clear"
        public static int userId;       //UserID in the database (by IP and useragent)
        public static int numOfDrawingsAllowed = 5; //Number of drawings and rectangles that each user is allowed to paint in the share room (-1 for unlimited)
        const string connStr = "Server = localhost\\SQLEXPRESS; Database = DrawingSheet; Trusted_Connection = True;";   //SQL server connection string
        const string txtPath = "C:/Users/omera/source/repos/DrawPad/DrawPad";       //IsPrivate.txt path

        //Runs on page load
        protected void Page_Load(object sender, EventArgs e)
        {

            clear = "false";
            ip = GetLocalIP();
            useragent = Request.UserAgent;
            isPrivate = System.IO.File.ReadAllText(txtPath + "./IsPrivate.txt");
            PrivateFromServer.Value = isPrivate;
            #region If new user then insert to Users database and get userID, if existing user then get userID
            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;

            command.CommandText = "SELECT UserID FROM Users WHERE Useragent = '" + useragent + "'";
            try
            {
                userId = (int)command.ExecuteScalar();
            }
            catch
            {
                command.CommandText = "insert into Users(IP,Useragent) values(@Ip,@userAgent)";
                command.Parameters.AddWithValue("@ip", ip);
                command.Parameters.AddWithValue("@userAgent", useragent);
                command.ExecuteNonQuery();
                command.CommandText = "SELECT UserID FROM Users WHERE Useragent = '" + useragent + "'";
                userId = (int)command.ExecuteScalar();
            }
            connection.Close();
            #endregion
            LoadBtn_Click(sender, e);
        }

        //User pressed "Save"
        protected void SaveBtn_Click(object sender, EventArgs e)
        {
            bool moreThanAllowed;

            isPrivate = PrivateToServer.Value;      //Is drawing/rectangle from private or shared room
            paintOrRect = PaintRect.Value;          //Is it a drawing or a rectangle
            clear = IsClearToServer.Value;          //Did user pressed "Clear" before "Save"

            #region Check how many drawings/rectangles has the user paint so far
            if (isPrivate == "false" && clear == "false" && numOfDrawingsAllowed > 0 && !ColorToServer.Value.Contains("FFFFFF"))
            {
                moreThanAllowed = CountDrwings(userId);

                if (moreThanAllowed)    //if reached the maximum number of drawings/rectangles
                {
                    MoreThanAllowed.Value = "true";
                    return;
                }
                else
                    MoreThanAllowed.Value = "false";
            }
            else
                MoreThanAllowed.Value = "false";
            #endregion

            if (clear == "true")    //User pressed "Clear" before "Save"
            {
                RemoveDrawings(isPrivate, userId);
                RemoveRects(isPrivate, userId);
            }
            else
            {
                SqlConnection connection = new SqlConnection();
                connection.ConnectionString = connStr;
                connection.Open();
                SqlCommand command = new SqlCommand();
                command.Connection = connection;

                if (paintOrRect == "false")     //Save drawing in database (false for paint)
                {
                    x = XcordsToServer.Value;
                    if (x == "") return;
                    y = YcordsToServer.Value;
                    drag = IsDraggingToServer.Value;
                    color = ColorToServer.Value;
                    width = PenWidthToServer.Value;
                    
                    command.CommandText = "insert into Drawings(Xcords,Ycords,isDragging,Color,PenWidth,UserID,isPrivate) values(@x, @y, @drag, @color, @width, @userId, @private)";
                    command.Parameters.AddWithValue("@x", x);
                    command.Parameters.AddWithValue("@y", y);
                    command.Parameters.AddWithValue("@drag", drag);
                    command.Parameters.AddWithValue("@color", color);
                    command.Parameters.AddWithValue("@width", width);
                    command.Parameters.AddWithValue("@userId", userId);
                    command.Parameters.AddWithValue("@private", isPrivate);

                }
                else             //Save rectangle in database
                {
                    rects = RectToServer.Value;
                    rectsColor = RectColorToServer.Value;
                    command.CommandText = "insert into Rects(Cords,RectColor,UserID,isPrivate) values(@rectCords, @rectColors, @userId, @private)";
                    command.Parameters.AddWithValue("@rectCords", rects);
                    command.Parameters.AddWithValue("@rectColors", rectsColor);
                    command.Parameters.AddWithValue("@userId", userId);
                    command.Parameters.AddWithValue("@private", isPrivate);
                }

                command.ExecuteNonQuery();
                connection.Close();
            }

            Page_Load(sender, e);   

        }

        //User pressed "Load" (also runs on page load and after user press "save")
        protected void LoadBtn_Click(object sender, EventArgs e)
        {
            MoreThanAllowed.Value = "false";
            //isPrivate = PrivateToServer.Value;

            GetDrawingRow(isPrivate, userId);
            GetRectRow(isPrivate, userId);

        }

        //User pressed "Clear", change clear parameter to true
        protected void ClearBtn_Click(object sender, EventArgs e)
        {
            clear = "true";
            IsClearFromServer.Value = clear;
        }

        //Get user's IP
        protected string GetLocalIP()
        {
            string localIP;
            using (Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, 0))
            {
                socket.Connect("8.8.8.8", 65530);
                IPEndPoint endPoint = socket.LocalEndPoint as IPEndPoint;
                localIP = endPoint.Address.ToString();
            }
            return localIP;
        }

        //Get drawing rows according to parameters "isprivate" and "userID"
        protected void GetDrawingRow(string isprivate, int userID)
        {

            string xcords = "";
            string ycords = "";
            string isdragging = "";
            string colors = "";
            string penWidth = "";
            int user;
            string prefix;
            string privateRow;
            bool firstTime = true;
            int firstDrawingId;
            int lastDrawingId;

            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;

            //Find minimum UserID
            command.CommandText = "SELECT MIN(DrawID) FROM Drawings";
            try
            {
                int firstIdread = (int)command.ExecuteScalar();
                firstDrawingId = firstIdread;
            }
            catch
            {
                XcordsFromServer.Value = "";
                YcordsFromServer.Value = "";
                IsDraggingFromServer.Value = "";
                ColorFromServer.Value = "";
                PenWidthFromServer.Value = "";
                return;
            }

            //Find maximum UserID
            command.CommandText = "SELECT MAX(DrawID) FROM Drawings";
            int lastIdread = (int)command.ExecuteScalar();
            lastDrawingId = lastIdread;

            while (firstDrawingId <= lastDrawingId)
            {
                //Seperates between two different drawings
                if (firstTime == true)
                {
                    prefix = "";
                }
                else
                {
                    prefix = ",false,";
                }
                command.CommandText = "select * from Drawings where DrawID = @id";
                command.Parameters.AddWithValue("@id", firstDrawingId++);
                SqlDataReader reader = command.ExecuteReader();

                //Get row according to the conditions
                while (reader.Read())
                {
                    privateRow = Convert.ToString(reader["isPrivate"]);
                    user = Convert.ToInt32(reader["UserID"]);
                    if ((privateRow == isprivate && isprivate == "false") || (privateRow == isprivate && isprivate == "true" && user == userId))
                    {
                        xcords += Convert.ToString(reader["Xcords"]) + ",";
                        ycords += Convert.ToString(reader["Ycords"]) + ",";
                        isdragging += prefix + Convert.ToString(reader["isDragging"]);
                        if (!firstTime)
                            isdragging = isdragging.Remove(isdragging.Length - 5);
                        colors += Convert.ToString(reader["Color"]) + ",";
                        penWidth += Convert.ToString(reader["PenWidth"]) + ",";
                        firstTime = false;
                    }
                }
                reader.Close();
                command.Parameters.RemoveAt("@id");
            }

            //Send back to client
            XcordsFromServer.Value = xcords;
            YcordsFromServer.Value = ycords;
            IsDraggingFromServer.Value = isdragging;
            ColorFromServer.Value = colors;
            PenWidthFromServer.Value = penWidth;
            IsClearFromServer.Value = clear;
            
            connection.Close();
        }

        //Get rectangles rows according to parameters "isprivate" and "userID"
        protected void GetRectRow(string isprivate, int userID)
        {
            string rect = "";
            string rectColor = "";
            string privateRow;
            int user;
            int firstId;
            int lastId;

            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;

            //Get minimum UserID
            command.CommandText = "SELECT MIN(RectID) FROM Rects";
            try
            {
                int firstIdread = (int)command.ExecuteScalar();
                firstId = firstIdread;
            }
            catch
            {
                RectFromServer.Value = "";
                RectColorFromServer.Value = "";
                return;
            }

            //Get maximum UserID
            command.CommandText = "SELECT MAX(RectID) FROM Rects";
            int lastIdread = (int)command.ExecuteScalar();
            lastId = lastIdread;

            while (firstId <= lastId)
            {
                command.CommandText = "select * from Rects where RectID = @id";
                command.Parameters.AddWithValue("@id", firstId++);
                SqlDataReader reader = command.ExecuteReader();

                //Get row according to the conditions
                while (reader.Read())
                {
                    privateRow = Convert.ToString(reader["isPrivate"]);
                    user = Convert.ToInt32(reader["UserID"]);
                    if ((privateRow == isprivate && isprivate == "false") || (privateRow == isprivate && isprivate == "true" && user == userId))
                    {
                        rect += Convert.ToString(reader["Cords"]) + ",";
                        rectColor += Convert.ToString(reader["RectColor"]) + ",";
                    }
                }
                reader.Close();
                command.Parameters.RemoveAt("@id");
            }

            //Send back to client
            RectFromServer.Value = rect;
            RectColorFromServer.Value = rectColor;
            IsClearFromServer.Value = clear;

            connection.Close();
        }

        //Remove drawing rows according to parameters "isprivate" and "userID", wether shared or private room, user is allowed to clear only his drawings
        protected void RemoveDrawings(string isprivate, int userID)
        {
            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;
            command.CommandText = "DELETE FROM Drawings WHERE isPrivate = '" + isprivate + "' AND UserID = '" + userID.ToString() + "'";
            command.ExecuteNonQuery();
            IsClearFromServer.Value = "true";
            connection.Close();
        }

        //Remove rectangles rows according to parameters "isprivate" and "userID", wether shared or private room, user is allowed to clear only his rectangles
        protected void RemoveRects(string isprivate, int userID)
        {

            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;

            command.CommandText = "DELETE FROM Rects WHERE isPrivate = '" + isprivate + "' AND UserID = '" + userID.ToString() + "'";

            command.ExecuteNonQuery();
            connection.Close();
            IsClearFromServer.Value = "true";
        }

        //Count number of drawings + rectangles of a user
        protected bool CountDrwings(int userID)
        {
            int count;

            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;
            command.CommandText = "SELECT COUNT(UserID) FROM Drawings WHERE UserID = '" + userID.ToString() + "' AND isPrivate = 'false' AND Color NOT LIKE '%FFFFFF%'";
            try
            {
                int sum = (int)command.ExecuteScalar();
                count = sum;
            }
            catch
            {
                count = 0;
            }
            command.CommandText = "SELECT COUNT(UserID) FROM Rects WHERE UserID = '" + userID.ToString() + "' AND isPrivate = 'false'";
            try
            {
                int sum = (int)command.ExecuteScalar();
                count += sum;
            }
            catch
            {
                return false;
            }

            if (count >= numOfDrawingsAllowed)
                return true;
            else
                return false;
        }

        //Find if point (x,y) is in a rectangle with opposite points (x1,y1) and (x3,y3)
        protected static bool IsPointInRectangle(int x1, int y1, int x3, int y3, int x, int y)
        {
            int x2 = x3, y2 = y1, x4 = x1, y4 = y3;
          
            // Calculate area of rectangle ABCD  
            float A = TriangleArea(x1, y1, x2, y2, x3, y3) +
                      TriangleArea(x1, y1, x4, y4, x3, y3);

            // Calculate area of triangle PAB  
            float A1 = TriangleArea(x, y, x1, y1, x2, y2);

            // Calculate area of triangle PBC  
            float A2 = TriangleArea(x, y, x2, y2, x3, y3);

            // Calculate area of triangle PCD  
            float A3 = TriangleArea(x, y, x3, y3, x4, y4);

            // Calculate area of triangle PAD 
            float A4 = TriangleArea(x, y, x1, y1, x4, y4);

            // Check if sum of A1, A2, A3   
            // and A4is same as A  
            return (A == A1 + A2 + A3 + A4);
            
        }

        //Calculate area of a triangle (for finding if a point is in rectangle)
        protected static float TriangleArea(int x1, int y1, int x2, int y2, int x3, int y3)
        {
            return (float)Math.Abs((x1 * (y2 - y3) +
                                x2 * (y3 - y1) +
                                x3 * (y1 - y2)) / 2.0);
        }

        //Erasing rectangle
        protected void EraseRectBtn_Click(object sender, EventArgs e)
        {
            int pointX, pointY;
            int firstId, lastId;
            string isprivate;
            string rectCords;
            int user;
            string privateRow;
            string check = "";
            string[] temp = new string[] { "" };
            int[] cordsArr;
            bool isInside = false;

            pointX = Convert.ToInt32(EraseRectX.Value);
            pointY = Convert.ToInt32(EraseRectY.Value);
            isprivate = PrivateToServer.Value;

            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;

            command.CommandText = "SELECT MIN(RectID) FROM Rects";
            try
            {
                int firstIdread = (int)command.ExecuteScalar();
                firstId = firstIdread;
            }
            catch
            {
                return;
            }

            command.CommandText = "SELECT MAX(RectID) FROM Rects";
            int lastIdread = (int)command.ExecuteScalar();
            lastId = lastIdread;

            while (firstId <= lastId)
            {
                command.CommandText = "select * from Rects where RectID = @id";
                command.Parameters.AddWithValue("@id", firstId);
                SqlDataReader reader = command.ExecuteReader();

                //Get row according to the conditions
                while (reader.Read())
                {
                    privateRow = Convert.ToString(reader["isPrivate"]);
                    user = Convert.ToInt32(reader["UserID"]);
                    if (privateRow == isprivate && user == userId)
                    {
                        rectCords = Convert.ToString(reader["Cords"]);
                        temp = rectCords.Split(',');
                        check = "Nothing";
                    }
                }
                reader.Close();
                command.Parameters.RemoveAt("@id");

                if (check == "")
                {
                    firstId++;
                    continue;
                }
                else
                    cordsArr = Array.ConvertAll(temp, int.Parse);


                isInside = IsPointInRectangle(cordsArr[0], cordsArr[1], cordsArr[2], cordsArr[3], pointX, pointY);
                if (isInside)
                {
                    command.CommandText = "DELETE FROM Rects WHERE RectID = '" + firstId.ToString() + "'";
                    command.ExecuteNonQuery();
                }
                firstId++;

            }

            connection.Close();
            LoadBtn_Click(sender, e);
        }

        //Switch to private room
        protected void PrivateServerBtn_Click(object sender, EventArgs e)
        {
            System.IO.File.WriteAllText(txtPath + "./IsPrivate.txt", "true");
            isPrivate = "true";
            Page_Load(sender, e);
        }

        //Switch to shared room
        protected void SharedServerBtn_Click(object sender, EventArgs e)
        {
            System.IO.File.WriteAllText(txtPath + "./IsPrivate.txt", "false");
            isPrivate = "false";
            Page_Load(sender, e);
        }

        //Undo
        protected void UndoCoverBtn_Click(object sender, EventArgs e)
        {
            int lastId;

            isPrivate = System.IO.File.ReadAllText(txtPath + "./IsPrivate.txt"); ;

            SqlConnection connection = new SqlConnection();
            connection.ConnectionString = connStr;
            connection.Open();
            SqlCommand command = new SqlCommand();
            command.Connection = connection;

            command.CommandText = "SELECT MAX(DrawID) FROM Drawings WHERE isPrivate = '" + isPrivate.ToString() + "' AND UserID = '" + userId + "'";

            try
            {
                lastId = (int)command.ExecuteScalar();
            }
            catch
            {
                UndoSuccess.Value = "false";
                return;
            }

            command.CommandText = "DELETE FROM Drawings WHERE DrawID = '" + lastId.ToString() + "'";

            command.ExecuteNonQuery();
            connection.Close();
            Page_Load(sender, e);

        }
    }
}