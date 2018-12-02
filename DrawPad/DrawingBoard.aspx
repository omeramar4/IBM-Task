<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DrawingBoard.aspx.cs" Inherits="DrawPad.DrawingBoard" %>

<style type="text/css">
    .box {
        display: flex;
    }

    .box2 {
        display: flex;
        flex-wrap: wrap;
        flex-direction: column;
        padding: 20px;
    }

    .box3 {
        display: flex;
        flex-wrap: wrap;
        flex-direction: column;
        padding: 20px;
    }

    .box4 {
        display: flex;
        flex-wrap: wrap;
        flex-direction: column;
        padding: 20px;
    }

    .box5 {
        display: flex;
        flex-wrap: wrap;
        flex-direction: column;
        padding: 20px;
    }

    #SharedBtn {
        width: 368px;
        height: 45px;
        font-size: 22px;
        font-weight: 700;
    }

    #PrivateBtn {
        width: 368px;
        height: 45px;
        font-size: 22px;
        font-weight: 700;
    }

</style>
<div class="box">
    <div id="canvasDiv"></div>
    <div>
        <div class="box2">      
            <input id="SharedBtn" type="button" value="Shared Room"  onclick="Shared()"/>
            <input id="PrivateBtn" type="button" value="Private Room" onclick="Private()"/>
        </div>
    
        <div class="box3">
            <p>Tools:</p>
            <input id="EraseBtn" type="button" value="Eraser" onclick="Eraser()"/>
            <input id="DrawRectBtn" type="button" value="Draw Rectangle" onclick="EnableRect()"/>
            <input id="EraseRectangleBtn" type="button" value="Erase Rectangle" onclick="EraseRect()"/>
            <input id="SaveImgBtn" type="button" value="Download Image" onclick="SaveToImage()"/>
            <input id="UndoBtn" type="button" value="Undo (Drawings Only)" onclick="Undo()"/>
        </div>

        <div class="box4">
            <div class="color-group">
                <p id="ChangeColorLbl">Choose Color:</p>
                <button id="black" onclick="ChangeColor('#000000')" value="#000000"></button>
                <button id="red" onclick="ChangeColor('#FF0000')" value="#FF0000"></button>
                <button id="green" onclick="ChangeColor('#00FF00')" value="#00FF00"></button>
                <button id="blue" onclick="ChangeColor('#0000FF')" value="#0000FF"></button>
                <button id="orange" onclick="ChangeColor('#FF8000')" value="#FF8000"></button>
                <button id="pink" onclick="ChangeColor('#FF00FF')" value="#FF00FF"></button>
                <button id="purple" onclick="ChangeColor('#9100FF')" value="#9100FF"></button>
                <button id="lightblue" onclick="ChangeColor('#0EFFFF')" value="#0EFFFF"></button>
                <button id="yellow" onclick="ChangeColor('#FFFF00')" value="#FFFF00"></button>
                <button id="brown" onclick="ChangeColor('#A44B00')" value="#A44B00"></button>
                <button id="forestgreen" onclick="ChangeColor('#00A44B')" value="#00A44B"></button>
                <button id="grey" onclick="ChangeColor('#D3D3D3')" value="#D3D3D3"></button>
                <button id="maroon" onclick="ChangeColor('#B03060')" value="#B03060"></button>
            </div>

            <div class="pen-width-group">
                <p id="ChangeWidthLbl">Choose Marker Size:</p>
                <button id="size1" onclick="ChangeWidth(5)" value="3"></button>
                <button id="size2" onclick="ChangeWidth(12)" value="7"></button>
                <button id="size3" onclick="ChangeWidth(17)" value="13"></button>
                <button id="size4" onclick="ChangeWidth(23)" value="20"></button>
                <button id="size5" onclick="ChangeWidth(35)" value="28"></button>
            </div>
        </div>

        <div class="box5">
            <p id="BackImageLbl">Choose background image:</p>
            <select id = "SelectImage" onchange="ChangeImage()">
                <option value="5">No Image</option>
                <option value = "1">Flower</option>
                <option value = "2">Jigglypuff</option>
                <option value = "3">Room</option>
                <option value = "4">Deadpool</option>
                <option value = "6">Chameleon</option>
                <option value = "7">Parrot</option>
            </select>
        </div>

    </div>
</div>



<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">
    <title></title>

    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" type="text/javascript"></script>
    <script type="text/javascript">

        //Client's Variables
        //--------------------------------------------------
        var clickX = new Array();       //Track mouse X coordinates
        var clickY = new Array();       //Track mouse Y coordinates
        var clickDrag = new Array();    //Track boolean dragging variable
        var clickColor = new Array();   //Track pen color
        var clickWidth = new Array();   //Track pen width
        var rectArray = new Array();    //Rectangle coordinates
        var rectColorArray = new Array();   //Rectangle colors
        
        var xCordsArrayFromServer = new Array();
        var yCordsArrayFromServer = new Array();
        var isDraggingArrayFromServer = new Array();
        var colorArrayFromServer = new Array();
        var penWidthArrayFromServer = new Array();
        var rectArrayFromServer = new Array();
        var rectColorFromServer = new Array();
        var isClearFromServer;

        var saveForFirstTime = localStorage.getItem("FirstTime");
        var isPrivate;// = localStorage.getItem("PrivateValue");       //Private or shared room
        var tempX = new Array();    //Current drawing X coordinates
        var tempY = new Array();    //Current drawing Y coordinates
        var tempDrag = new Array(); //Current isDragging values
        var tempColor;              //Current color
        var tempWidth;              //Current pen width
        var tempRect;               //Current rectangle coordinates
        var tempRectColor;          //Current rectangle color
        var paint;                  //Is currently drawing
        var clear = false;          //Is page cleared
        var isErasing = false;      //Is currently erasing
        var curColor = localStorage.getItem("CurrentColor");        //Get color from browser localstorage
        var paintWidth = localStorage.getItem("CurrentWidth");      //Get marker size from browser localstorage
        var enableWidthChange = true;     //Enable pen width change
        var enableColorChange = true;     //Enable pen color change
        var enableEraser = true;    //Enable eraser
        var enableRectEraser = true;    //Enable rectangles erase
        var enableImageDownload = true;     //Enable the option for saving the image on the local drive
        var enableRectDraw = true;      //Enable drawing rectangles
        var enableImageDrawing = true; //Enable drawing inside an image
        var isDrawRect = false;     //true if user currently drawing a rectangle
        var colorBtnHeight = 20;    //For color buttons style
        var isErasingRect = false;  //User pressed "Erase Rectangle"
        var startRectX;     //Starting X coordinate of the rectangle
        var startRectY;     //Starting Y coordinate of the rectangle
        var endRectX;       //End X coordinate of the rectangle
        var endRectY;       //End Y coordinate of the rectangle
        var prevX;          //Keeps previous end X coordinate
        var prevY;          //Keeps previous end Y coordinate
        var prevColorValue = curColor;  //Keep the previous color for returning from eraser mode
        var rects;      //Rectangles coordinates from server
        var rectColors; //Rectangles colors from server
        var undoSuccess;    //Is undo worked?
        //--------------------------------------------------

        //Set Canvas properties
        //--------------------------------------------------
        canvasDiv = document.getElementById('canvasDiv');
        var canvas = document.createElement('canvas');
        canvas.setAttribute('width', 800);
        canvas.setAttribute('height', 600);
        canvas.setAttribute('id', 'canvas');
        canvas.style.border = '2px solid #000';
        canvasDiv.appendChild(canvas);
        if (typeof G_vmlCanvasManager != 'undefined') {
            canvas = G_vmlCanvasManager.initElement(canvas);
        }
        context = canvas.getContext("2d");
        //--------------------------------------------------

        //Color Buttons Properties
        //--------------------------------------------------
        document.getElementById("black").style.backgroundColor = document.getElementById("black").value;
        document.getElementById("black").style.height = colorBtnHeight;
        document.getElementById("black").style.width = colorBtnHeight;
        document.getElementById("black").hidden = !enableColorChange;
        document.getElementById("red").style.backgroundColor = document.getElementById("red").value;
        document.getElementById("red").style.height = colorBtnHeight;
        document.getElementById("red").style.width = colorBtnHeight;
        document.getElementById("red").hidden = !enableColorChange;
        document.getElementById("green").style.backgroundColor = document.getElementById("green").value;
        document.getElementById("green").style.height = colorBtnHeight;
        document.getElementById("green").style.width = colorBtnHeight;
        document.getElementById("green").hidden = !enableColorChange;
        document.getElementById("blue").style.backgroundColor = document.getElementById("blue").value;
        document.getElementById("blue").style.height = colorBtnHeight;
        document.getElementById("blue").style.width = colorBtnHeight;
        document.getElementById("blue").hidden = !enableColorChange;
        document.getElementById("orange").style.backgroundColor = document.getElementById("orange").value;
        document.getElementById("orange").style.height = colorBtnHeight;
        document.getElementById("orange").style.width = colorBtnHeight;
        document.getElementById("orange").hidden = !enableColorChange;
        document.getElementById("pink").style.backgroundColor = document.getElementById("pink").value;
        document.getElementById("pink").style.height = colorBtnHeight;
        document.getElementById("pink").style.width = colorBtnHeight;
        document.getElementById("pink").hidden = !enableColorChange;
        document.getElementById("purple").style.backgroundColor = document.getElementById("purple").value;
        document.getElementById("purple").style.height = colorBtnHeight;
        document.getElementById("purple").style.width = colorBtnHeight;
        document.getElementById("purple").hidden = !enableColorChange;
        document.getElementById("lightblue").style.backgroundColor = document.getElementById("lightblue").value;
        document.getElementById("lightblue").style.height = colorBtnHeight;
        document.getElementById("lightblue").style.width = colorBtnHeight;
        document.getElementById("lightblue").hidden = !enableColorChange;
        document.getElementById("yellow").style.backgroundColor = document.getElementById("yellow").value;
        document.getElementById("yellow").style.height = colorBtnHeight;
        document.getElementById("yellow").style.width = colorBtnHeight;
        document.getElementById("yellow").hidden = !enableColorChange;
        document.getElementById("brown").style.backgroundColor = document.getElementById("brown").value;
        document.getElementById("brown").style.height = colorBtnHeight;
        document.getElementById("brown").style.width = colorBtnHeight;
        document.getElementById("brown").hidden = !enableColorChange;
        document.getElementById("forestgreen").style.backgroundColor = document.getElementById("forestgreen").value;
        document.getElementById("forestgreen").style.height = colorBtnHeight;
        document.getElementById("forestgreen").style.width = colorBtnHeight;
        document.getElementById("forestgreen").hidden = !enableColorChange;
        document.getElementById("grey").style.backgroundColor = document.getElementById("grey").value;
        document.getElementById("grey").style.height = colorBtnHeight;
        document.getElementById("grey").style.width = colorBtnHeight;
        document.getElementById("grey").hidden = !enableColorChange;
        document.getElementById("maroon").style.backgroundColor = document.getElementById("maroon").value;
        document.getElementById("maroon").style.height = colorBtnHeight;
        document.getElementById("maroon").style.width = colorBtnHeight;
        document.getElementById("maroon").hidden = !enableColorChange;
        document.getElementById("ChangeColorLbl").hidden = !enableColorChange;
        //--------------------------------------------------

        //Width Buttons Properties
        //--------------------------------------------------
        document.getElementById("size1").textContent = "1";
        document.getElementById("size1").style.height = colorBtnHeight;
        document.getElementById("size1").style.width = colorBtnHeight;
        document.getElementById("size1").hidden = !enableWidthChange;
        document.getElementById("size2").textContent = "2";
        document.getElementById("size2").style.height = colorBtnHeight;
        document.getElementById("size2").style.width = colorBtnHeight;
        document.getElementById("size2").hidden = !enableWidthChange;
        document.getElementById("size3").textContent = "3";
        document.getElementById("size3").style.height = colorBtnHeight;
        document.getElementById("size3").style.width = colorBtnHeight;
        document.getElementById("size3").hidden = !enableWidthChange;
        document.getElementById("size4").textContent = "4";
        document.getElementById("size4").style.height = colorBtnHeight;
        document.getElementById("size4").style.width = colorBtnHeight;
        document.getElementById("size4").hidden = !enableWidthChange;
        document.getElementById("size5").textContent = "5";
        document.getElementById("size5").style.height = colorBtnHeight;
        document.getElementById("size5").style.width = colorBtnHeight;
        document.getElementById("size5").hidden = !enableWidthChange;
        document.getElementById("ChangeWidthLbl").hidden = !enableWidthChange;
        //--------------------------------------------------

        //Activates at page load
        function init() {

            //document.body.style.background = "#f3f3f3 url('Background.jpg') no-repeat right top";
            document.getElementById('EraseRectBtn').hidden = true;
            document.getElementById('PrivateServerBtn').hidden = true;
            document.getElementById('SharedServerBtn').hidden = true;
            document.getElementById('UndoCoverBtn').hidden = true;
            isErasing = false;

            isPrivate = document.getElementById('<%=PrivateFromServer.ClientID%>').value;
            undoSuccess = document.getElementById('<%=UndoSuccess.ClientID%>').value;

            if (undoSuccess == "false") {
                alert("No drawing to undo");
                undoSuccess = "true";
            }

            if (saveForFirstTime != "true") {
                isPrivate = "false";
                localStorage.setItem("FirstTime", "true");
                saveForFirstTime = "false"
            }

            
            document.getElementById('EraseBtn').hidden = !enableEraser;
            document.getElementById('EraseRectangleBtn').hidden = !enableRectEraser;
            document.getElementById('SaveImgBtn').hidden = !enableImageDownload;
            document.getElementById('DrawRectBtn').hidden = !enableRectDraw;
           
            //"Private Room" and "Shared Room" style
            if (isPrivate == "true") {
                document.getElementById('SharedBtn').style.borderStyle = 'outset';
                document.getElementById('PrivateBtn').style.borderStyle = 'inset';
                document.getElementById('PrivateBtn').style.backgroundColor = "#00FFFF";
                document.getElementById('SharedBtn').style.backgroundColor = "";
                document.getElementById('SelectImage').hidden = false;
                document.getElementById('BackImageLbl').hidden = false;
                canvas.style.background = "#f3f3f3 url('image" + localStorage.getItem("Image") + ".png') no-repeat right top";
                document.getElementById('SelectImage').value = localStorage.getItem("Image");
            }
            else {
                document.getElementById('SharedBtn').style.borderStyle = 'inset';
                document.getElementById('PrivateBtn').style.borderStyle = 'outset';
                document.getElementById('SharedBtn').style.backgroundColor = "#00FFFF";
                document.getElementById('PrivateBtn').style.backgroundColor = "";
                document.getElementById('SelectImage').hidden = true;
                document.getElementById('BackImageLbl').hidden = true;
                canvas.style.background = "#FFFFFF";
            }

            //Return from server after clear or not
            isClearFromServer = document.getElementById('<%=IsClearFromServer.ClientID%>').value;
            if (isClearFromServer == "true") 
                clear = true;
            else
                clear = false;

            //Is user reached the maximum amount of drawings/rectangles allowed
            var tooMuch = document.getElementById('<%=MoreThanAllowed.ClientID%>').value;
            if (tooMuch == "true")
                alert("You reached the maximum number of drawings");

            if (!clear) {
                //Get drawings and rectangles from server
                xCordsArrayFromServer = document.getElementById('<%=XcordsFromServer.ClientID%>').value.split(',');
                yCordsArrayFromServer = document.getElementById('<%=YcordsFromServer.ClientID%>').value.split(',');
                isDraggingArrayFromServer = document.getElementById('<%=IsDraggingFromServer.ClientID%>').value.split(',');
                colorArrayFromServer = document.getElementById('<%=ColorFromServer.ClientID%>').value.split(',');
                penWidthArrayFromServer = document.getElementById('<%=PenWidthFromServer.ClientID%>').value.split(',');
                rectArrayFromServer = document.getElementById('<%=RectFromServer.ClientID%>').value.split(',');
                rectColorArrayFromServer = document.getElementById('<%=RectColorFromServer.ClientID%>').value.split(',');

                //Convert string to boolean
                var isDraggingStrToBool = [];
                for (var i = 0; i < isDraggingArrayFromServer.length; i++) {
                    if (isDraggingArrayFromServer[i] == "true") {
                        isDraggingStrToBool.push(true);
                    }
                    else {
                        isDraggingStrToBool.push(false);
                    }
                }

                //Convert string to int
                var Xcords = xCordsArrayFromServer.map(function (item) {
                    return parseInt(item, 10);
                });
                var Ycords = yCordsArrayFromServer.map(function (item) {
                    return parseInt(item, 10);
                });
                var penWidth = penWidthArrayFromServer.map(function (item) {
                    return parseInt(item, 10);
                });
                rects = rectArrayFromServer.map(function (item) {
                    return parseInt(item, 10);
                });

                //colors of drawings and rectangles
                var colors = colorArrayFromServer;
                rectColors = rectColorArrayFromServer;

                clickX = Xcords;
                clickY = Ycords;
                clickDrag = isDraggingStrToBool;
                clickColor = colors;
                clickWidth = penWidth;
            }

            else {
                clear = false;
            }

            //Paint drawings and rectangles from server
            redraw();
            redrawRects();
        }

        //Canvas Events
        //Mousedown event - user starts drawing
        $('#canvas').mousedown(function (e) {
            document.getElementById('IsClearToServer').value = "false";

            clickX = new Array();
            clickY = new Array();
            clickDrag = new Array();
            clickColor = new Array();
            clickWidth = new Array();

            if (!isDrawRect && !isErasingRect) {      //Drawing
                paint = true;
                addClick(e.pageX - this.offsetLeft, e.pageY - this.offsetTop);
                redraw();
            }
            else if (isDrawRect && !isErasingRect) {      //Rectangle
                paint = true;
                rectArray = new Array();
                rectColorArray = new Array();
                startRectX = e.pageX - this.offsetLeft;     //Starting X coordinate of the current rectangle
                startRectY = e.pageY - this.offsetTop;      //Starting Y coordinate of the current rectangle
                prevX = startRectX;
                prevY = startRectY;
            }

            if (isErasingRect) {    //User pressed "Erase Rectangle"
                document.getElementById('EraseRectX').value = e.pageX - this.offsetLeft;
                document.getElementById('EraseRectY').value = e.pageY - this.offsetTop;

                var id = '<%= EraseRectBtn.ClientID%>';
                $('#' + id).click();

                isErasingRect = false;
            }
        });

        //Mousemove event - user is drawing (the mouse is down)
        $('#canvas').mousemove(function (e) {
            if (paint && !isDrawRect) {     //Drawing
                addClick(e.pageX - this.offsetLeft, e.pageY - this.offsetTop, true);
                redraw();
            }
            if (paint && isDrawRect) {      //Rectangles
                endRectX = e.pageX - this.offsetLeft;
                endRectY = e.pageY - this.offsetTop;
                DrawRect();

                //Save previous coordinates to delete previous rectangle
                prevX = endRectX;       
                prevY = endRectY;       
            }
        });

        //Mouseup event - user stops drawing
        $('#canvas').mouseup(function (e) {
            paint = false;

            tempColor = curColor;


            if (!isDrawRect) {      //Drawing
                //Save drawing's data to transfer to the server
                tempX = clickX.slice(0, clickX.length);
                tempY = clickY.slice(0, clickY.length);
                tempDrag = clickDrag.slice(0, clickDrag.length);
                tempColor = clickColor.slice(0, clickColor.length);
                tempWidth = clickWidth.slice(0, clickWidth.length);
                document.getElementById('XcordsToServer').value = tempX.join(',');
                document.getElementById('YcordsToServer').value = tempY.join(',');
                document.getElementById('IsDraggingToServer').value = tempDrag.join(',');
                document.getElementById('ColorToServer').value = tempColor.join(',');
                document.getElementById('PenWidthToServer').value = tempWidth;
                document.getElementById('PaintRect').value = "false";
                localStorage.setItem("CurrentWidth", paintWidth);       //Store width in local store to remain after refresh
            }
            else {              //Rectangle
                //Save rectangle's data to transfer to the server
                isDrawRect = false;     //Done painting rectangle
                var btn = document.getElementById('DrawRectBtn')
                btn.style.borderStyle = (btn.style.borderStyle !== 'inset' ? 'inset' : 'outset');
                rectArray.push(startRectX);
                rectArray.push(startRectY);
                rectArray.push(endRectX);
                rectArray.push(endRectY);
                rectColorArray.push(curColor);
                tempRect = rectArray.slice(0, rectArray.length);
                document.getElementById('RectToServer').value = tempRect.join(',');
                document.getElementById('RectColorToServer').value = curColor;
                document.getElementById('PaintRect').value = "true";
            }

            document.getElementById('PrivateToServer').value = isPrivate;
            if (curColor != "#FFFFFF")
                localStorage.setItem("CurrentColor", curColor);     //Store color in local store to remain after refresh

            //Activate "Save" button
            if (!isErasingRect) {
                var id = '<%= SaveBtn.ClientID%>';
                $('#' + id).click();
            }


        });

        //Mouseleave event - user's mouse out of canvas borders (even if in the middle of drawing it stops)
        $('#canvas').mouseleave(function (e) {
            paint = false;
        });

        //For drawing tracking
        function addClick(x, y, dragging) {
            clickX.push(x);
            clickY.push(y);
            clickDrag.push(dragging);
            clickColor.push(curColor);
            clickWidth.push(paintWidth);
        }

        //Paint drawings
        function redraw() {
            context.lineJoin = "round";

            for (var i = 0; i < clickX.length; i++) {
                context.beginPath();
                if (clickDrag[i] && i && !isNaN(clickX[i - 1])) {
                    context.moveTo(clickX[i - 1], clickY[i - 1]);
                } else {
                    context.moveTo(clickX[i] - 1, clickY[i]);
                }
                context.lineTo(clickX[i], clickY[i]);
                context.closePath();
                context.strokeStyle = clickColor[i];
                context.lineWidth = clickWidth[i];
                context.stroke();
            }
        }

        //Paint rectangles
        function redrawRects() {
            var j = 0;
            try {
                if (rectColorArrayFromServer.length > 0) {
                    for (var i = 0; i < rectColorArrayFromServer.length; i++) {
                        context.fillStyle = rectColorArrayFromServer[i];
                        context.fillRect(rects[j], rects[j + 1], rects[j + 2] - rects[j], rects[j + 3] - rects[j + 1]);
                        j += 4;
                    }
                }
            }
            catch {

            }
        }

        //Color change function
        function ChangeColor(color) {
            if (isErasing == false) {
                curColor = color;
                prevColorValue = curColor;
            }
            else {
                alert("Can't change color while erasing");
                document.getElementById('selColor').value = prevColorValue;
            }
        }

        //Pen width change function
        function ChangeWidth(size) {
            paintWidth = size;
        }

        //User pressed "Clear"
        function ClearCanvas() {
            clear = true;
            document.getElementById('IsClearToServer').value = "true";
            document.getElementById('PrivateToServer').value = isPrivate;
            context.clearRect(0, 0, context.canvas.width, context.canvas.height); // Clears the canvas
        }

        //Enable or disable eraser
        function Eraser() {
            var btn = document.getElementById('EraseBtn')
            btn.style.borderStyle = (btn.style.borderStyle !== 'inset' ? 'inset' : 'outset'); 
            if (isErasing == false) {
                curColor = "#FFFFFF";
                isErasing = true;
            }
            else {
                isErasing = false;
                curColor = "#000000";
            }

        }

        //Draw rectangle in real time
        function DrawRect() {

            context.fillStyle = "#FFFFFF";
            context.fillRect(startRectX, startRectY, prevX - 4 - startRectX, prevY - 4 - startRectY);
            context.fillRect(startRectX, startRectY, prevX - 4 - startRectX, prevY + 4 - startRectY);
            context.fillRect(startRectX, startRectY, prevX + 4 - startRectX, prevY - 4 - startRectY);
            context.fillRect(startRectX, startRectY, prevX + 4 - startRectX, prevY + 4 - startRectY);
            context.fillStyle = curColor;
            context.fillRect(startRectX, startRectY, endRectX - startRectX, endRectY - startRectY);

        }

        //User pressed "Draw Rectangles"
        function EnableRect() {
            var btn = document.getElementById('DrawRectBtn')
            btn.style.borderStyle = (btn.style.borderStyle !== 'inset' ? 'inset' : 'outset');
            if (isDrawRect == false) {
                isDrawRect = true;
            }
            else {
                isDrawRect = false;
            }
        }

        //User pressed "Private Room"
        function Private() {
            isPrivate = true;
            document.getElementById('PrivateToServer').value = isPrivate;
            var id = '<%= PrivateServerBtn.ClientID%>';
            $('#' + id).click();
        }

        //User pressed "Shared Room"
        function Shared() {
            isPrivate = false;
            document.getElementById('PrivateToServer').value = isPrivate;
            var id = '<%= SharedServerBtn.ClientID%>';
            $('#' + id).click();
        }

        //Save canvas as image
        function SaveToImage() {
            var image = canvas.toDataURL("image/png").replace("image/png", "image/octet-stream");  
            window.location.href=image; // It will save locally
        }

        function ChangeImage() {
            localStorage.setItem("Image", document.getElementById('SelectImage').value);
            if (document.getElementById('SelectImage').value == "5") {
                canvas.style.background = "#FFFFFF";
            }
            else
                canvas.style.background = "#f3f3f3 url('image" + document.getElementById('SelectImage').value + ".png') no-repeat right top";
        }

        function EraseRect() {
            var btn = document.getElementById('EraseRectangleBtn')
            btn.style.borderStyle = (btn.style.borderStyle !== 'inset' ? 'inset' : 'outset');
            if (!isErasingRect) {
                isErasingRect = true;
            }
            else {
                isErasingRect = false;
            }
        }

        function Undo() {
            var id = '<%= UndoCoverBtn.ClientID%>';
            $('#' + id).click();
        }

    </script>

</head>
<body onload="init()">
    <form id="form1" runat="server">

        <div>
            <p id="PrintIP"></p>
            <p id="PrintUseragent"></p>
        </div>

        <div>
            <asp:Button ID="SaveBtn" runat="server" OnClick="SaveBtn_Click" Text="Save" Font-Bold="true" Font-Size="Large" Width="266px" />
            <asp:Button ID="LoadBtn" runat="server" OnClick="LoadBtn_Click" Text="Load" Font-Bold="true" Font-Size="Large" Width="266px" />
            <asp:Button ID="ClearBtn" runat="server" OnClientClick="ClearCanvas()" Text="Clear" OnClick="ClearBtn_Click" Font-Bold="true" Font-Size="Large" Width="266px" />
            <asp:Button ID="EraseRectBtn" runat="server" OnClick="EraseRectBtn_Click" Text="Erase Rectangle" />
            <asp:Button ID="PrivateServerBtn" runat="server" Text="Private" OnClick="PrivateServerBtn_Click" />
            <asp:Button ID="SharedServerBtn" runat="server" Text="Shared" OnClick="SharedServerBtn_Click" />
            <asp:Button ID="UndoCoverBtn" runat="server" OnClick="UndoCoverBtn_Click" Text="Undo" />
        </div>

        <div>
            <input id="XcordsToServer" type="hidden" runat="server" />
            <input id="YcordsToServer" type="hidden" runat="server" />
            <input id="IsDraggingToServer" type="hidden" runat="server" />
            <input id="ColorToServer" type="hidden" runat="server" />
            <input id="IsClearToServer" type="hidden" runat="server" />
            <input id="PenWidthToServer" type="hidden" runat="server" />
            <input id="RectToServer" type="hidden" runat="server" />
            <input id="RectColorToServer" type="hidden" runat="server" />
            <input id="XcordsFromServer" type="hidden" runat="server" />
            <input id="YcordsFromServer" type="hidden" runat="server" />
            <input id="IsDraggingFromServer" type="hidden" runat="server" />
            <input id="ColorFromServer" type="hidden" runat="server" />
            <input id="IsClearFromServer" type="hidden" runat="server" />
            <input id="PenWidthFromServer" type="hidden" runat="server" />
            <input id="RectFromServer" type="hidden" runat="server" />
            <input id="RectColorFromServer" type="hidden" runat="server" />
            <input id="MoreThanAllowed" type="hidden" runat="server" />
            <input id="PaintRect" type="hidden" runat="server" />
            <input id="PrivateToServer" type="hidden" runat="server" />
            <input id="EraseRectX" type="hidden" runat="server" />
            <input id="EraseRectY" type="hidden" runat="server" />
            <input id="PrivateFromServer" type="hidden" runat="server" />
            <input id="UndoSuccess" type="hidden" runat="server" />
        </div>

    </form>
</body>
</html>
