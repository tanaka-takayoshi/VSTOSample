using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Windows.Forms.Integration;
using CustomControlLibary;

namespace VSTOWord
{
    public partial class MyTaskPane : UserControl
    {
        public UserControl1 MyControl { get; private set; }
        public MyTaskPane()
        {
            InitializeComponent();
        }

        private void MyTaskPane_Load(object sender, EventArgs e)
        {
            var ehost = new ElementHost {Dock = DockStyle.Fill};
            MyControl = new UserControl1();
            ehost.Child = MyControl;
            Controls.Add(ehost);
        }
    }
}
