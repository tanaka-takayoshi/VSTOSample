using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Microsoft.AspNet.SignalR.Client;
using PowerPoint = Microsoft.Office.Interop.PowerPoint;
using Office = Microsoft.Office.Core;

namespace PowerPointVSTOSignalR
{
    public partial class ThisAddIn
    {
        private HubConnection Connection;

        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            //TODO サーバーのURLを指定
            Connection = new HubConnection("http://localhost:30852/signalr");
            Connection.Closed += Connection_Closed;
            var hubProxy = Connection.CreateHubProxy("OperateHub");
            
            //Handle incoming event from server: use Invoke to write to console from SignalR's thread
            hubProxy.On("Run", () =>
            {
                Globals.ThisAddIn.Application.ActivePresentation.SlideShowSettings.Run();
            });
            hubProxy.On("Go", () =>
            {
                Globals.ThisAddIn.Application.ActivePresentation.SlideShowWindow.View.Next();
            });
            hubProxy.On("Back", () =>
            {
                Globals.ThisAddIn.Application.ActivePresentation.SlideShowWindow.View.Previous();
            });
            try
            {
                Connection.Start().Wait();
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
            if (Connection != null)
            {
                Connection.Stop();
                Connection.Dispose();
            }
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
            Connection_Closed();
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
