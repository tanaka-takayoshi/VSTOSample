using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;
using Microsoft.Office.Tools.Excel;
using Microsoft.AspNet.SignalR.Client.Hubs;
using Microsoft.AspNet.SignalR.Client;
using System.Diagnostics;

namespace ExcelVSTOSignalR
{
    public partial class ThisAddIn
    {
        private HubConnection connection;

        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            // TODO ここにサーバー側のURLを指定
            connection = new HubConnection("http://localhost:33103/signalr");
            connection.Closed += Connection_Closed;
            var hubProxy = connection.CreateHubProxy("MyHub");
            var i = 1;
            //Handle incoming event from server: use Invoke to write to console from SignalR's thread
            hubProxy.On<string, string>("AddNewMessageToPage", (name, message) =>
            {
                var activeSheet = Globals.ThisAddIn.Application.ActiveSheet as Excel.Worksheet;
                activeSheet.Cells[i, 1] = name;
                activeSheet.Cells[i, 2] = message;
                ++i;
            });
            try
            {
                connection.Start().Wait();
            }
            catch (Exception)
            {
                //StatusText.Text = "Unable to connect to server: Start server before connecting clients.";
                //No connection: Don't enable Send button or show chat UI
                return;
            }
        }

        private void Connection_Closed()
        {
            if (connection != null)
            {
                connection.Stop();
                connection.Dispose();
            }
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO で生成されたコード

        /// <summary>
        /// デザイナーのサポートに必要なメソッドです。
        /// このメソッドの内容をコード エディターで変更しないでください。
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisAddIn_Startup);
            this.Shutdown += new System.EventHandler(ThisAddIn_Shutdown);
        }
        
        #endregion
    }
}
