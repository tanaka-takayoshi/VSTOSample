using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Google.Apis.Auth.OAuth2;
using Microsoft.Office.Tools.Ribbon;
using Google.Apis.Calendar.v3;
using Google.Apis.Calendar.v3.Data;
using Google.Apis.Services;
using Microsoft.Office.Interop.Outlook;
using System.Threading.Tasks;

namespace GoogleCalendaySync
{
    public partial class MyRibbon
    {
        private CalendarService calendarService;

        private void MyRibbon_Load(object sender, RibbonUIEventArgs e)
        {

        }

        private void button1_Click(object sender, RibbonControlEventArgs e)
        {
            ThreadPool.QueueUserWorkItem(_=>
            { 
                SyncAsync();
            });
        }

        private void SyncAsync()
        {
            //TODO とりあえず同期対象のカレンダーを直指定
            var account = "hoge@gmail.com";

            calendarService = calendarService ?? AuthenticateCalendar(account);

            //TODO Outlookに表示するカレンダー名
            var calendarName = string.Format("GSyncCalendar ({0})", account);
            var calendar = GetOrCreateCalendar(calendarName);
            var items = new List<Event>();
            string nextPageToken = null;
            while (true)
            {
                var res = calendarService.Events.List(account);
                res.PageToken = nextPageToken;
                var result = res.Execute();
                items.AddRange(result.Items);
                nextPageToken = result.NextPageToken;
                if (nextPageToken == null)
                    break;
            }


            var events = calendar.Items.OfType<AppointmentItem>().ToArray();
            var props = typeof(Event).GetProperties();
            foreach (var ev in items)
            {
                //Dump
                //props.Select(p => string.Format("{0}={1}", p.Name, ConvertToString(p.GetValue(ev, null))))
                //    .ToList()
                //    .ForEach(p => Debug.WriteLine(p));
                //Debug.WriteLine("");
                var oldEvent = events.Where(e => e.UserProperties["google-calendar-event-id"] != null)
                    .FirstOrDefault(e => e.UserProperties["google-calendar-event-id"].Value == ev.Id);
                if (oldEvent != null)
                {
                    oldEvent.Subject = ev.Summary;
                    oldEvent.Body = ev.Description;
                    if (ev.Start.Date != null)
                    {
                        oldEvent.AllDayEvent = true;
                        oldEvent.Start = DateTime.ParseExact(ev.Start.Date, "yyyy-mm-dd", DateTimeFormatInfo.InvariantInfo);
                    }
                    if (ev.Start.DateTime.HasValue)
                    {
                        oldEvent.Start = ev.Start.DateTime.Value;
                    }

                    if (ev.End.DateTime.HasValue)
                    {
                        oldEvent.End = ev.End.DateTime.Value;
                    }
                    oldEvent.Location = ev.Location;
                    oldEvent.Save();
                }
                else
                {
                    var newEvent = (AppointmentItem)calendar.Items.Add(OlItemType.olAppointmentItem);
                    newEvent.Subject = ev.Summary;
                    newEvent.Body = ev.Description;
                    if (ev.Start.Date != null)
                    {
                        newEvent.AllDayEvent = true;
                        newEvent.Start = DateTime.ParseExact(ev.Start.Date, "yyyy-mm-dd", DateTimeFormatInfo.InvariantInfo);
                    }
                    if (ev.Start.DateTime.HasValue)
                    {
                        newEvent.Start = ev.Start.DateTime.Value;
                    }

                    if (ev.End.DateTime.HasValue)
                    {
                        newEvent.End = ev.End.DateTime.Value;
                    }
                    newEvent.Location = ev.Location;
                    var prop = newEvent.UserProperties.Add("google-calendar-event-id", OlUserPropertyType.olText, false, true);
                    prop.Value = ev.Id;
                    newEvent.Save();
                }

            }

            var application = Globals.ThisAddIn.Application;
            application.ActiveExplorer().SelectFolder(calendar);
            application.ActiveExplorer().CurrentFolder.Display();
            
            MessageBox.Show("同期しました");
        }

        private static CalendarService AuthenticateCalendar(string account)
        {
            var scopes = new[] { CalendarService.Scope.Calendar };
            // TODO Googleの開発者コンソールからAPIの認証キーを作成して指定してください
            var credential =
                GoogleWebAuthorizationBroker.AuthorizeAsync(new ClientSecrets
                {
                    ClientId = "ClientId",
                    ClientSecret = "ClientSecret"
                }, scopes, account, CancellationToken.None).Result;

            var service = new CalendarService(new BaseClientService.Initializer
            {
                ApplicationName = "GCalendar",
                HttpClientInitializer = credential
            });
            return service;
        }
        private string ConvertToString(object v)
        {
            var data = v as Event.CreatorData;
            if (data != null)
            {
                return data.Id + "," + data.DisplayName + " " +
                       data.Email;
            }
            else
            {
                var time = v as EventDateTime;
                if (time != null)
                {
                    return time.DateTimeRaw;
                }
                else
                {
                    return v == null ? "" : v.ToString();
                }
            }
        }

        private MAPIFolder GetOrCreateCalendar(string calendarName)
        {
            var application = Globals.ThisAddIn.Application;
            var primaryCalendar = application.ActiveExplorer().Session.GetDefaultFolder(OlDefaultFolders.olFolderCalendar);
            var calendar = primaryCalendar.Folders.Cast<MAPIFolder>().FirstOrDefault(personalCalendar => personalCalendar.Name == calendarName);
            if (calendar != null)
                return calendar;

            calendar = primaryCalendar
                    .Folders.Add(calendarName,
                        OlDefaultFolders.olFolderCalendar);
            return calendar;

        }
    }
}
