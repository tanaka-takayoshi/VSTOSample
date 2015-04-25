using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.AspNet.SignalR;

namespace PowerPointVSTOSignalR.Server
{
    public class OperateHub : Hub
    {
        public void Hello()
        {
            Clients.All.hello();
        }

        public void Go()
        {
            Clients.All.go();
        }

        public void Back()
        {
            Clients.All.back();
        }

        public void Run()
        {
            Clients.All.run();
        }
    }
}