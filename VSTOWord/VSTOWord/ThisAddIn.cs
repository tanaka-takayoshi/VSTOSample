using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Xml.Linq;
using Codeplex.Data;
using Microsoft.Office.Tools;
using Word = Microsoft.Office.Interop.Word;
using Office = Microsoft.Office.Core;
using Microsoft.Office.Tools.Word;
using System.Diagnostics;

namespace VSTOWord
{
    public partial class ThisAddIn
    {
        private MyTaskPane myTaskpane;

        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            myTaskpane = new MyTaskPane();
            var taskPane = CustomTaskPanes.Add(myTaskpane, "Flickr");
            taskPane.Visible = true;
            myTaskpane.MyControl.SendEvent += MyControl_SendEvent;
        }

        void MyControl_SendEvent(object sender, string[] e)
        {
            Globals.ThisAddIn.Application.ActiveDocument.Shapes.AddPicture(e[1]);
            myTaskpane.MyControl.Sync("inserted");
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
