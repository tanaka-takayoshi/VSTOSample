using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceModel.Syndication;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Xml;
using FlickrNet;

namespace CustomControlLibary
{
    /// <summary>
    /// UserControl1.xaml の相互作用ロジック
    /// </summary>
    public partial class UserControl1 : UserControl
    {
        private Flickr flickr;
        //WPF側のアクションからVSTOの処理を実行するために、イベントを公開する
        public event EventHandler<string[]> SendEvent = (s, e) => { };
        public UserControl1()
        {
            InitializeComponent();
            //TODO FlickrのAPIキーを指定
            flickr = new Flickr("key");
        }

        public void Sync(string status)
        {
            statusText.Text = status;
        }

        

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            statusText.Text = "executing...";
            var photos = flickr.PhotosSearch(new PhotoSearchOptions
            {
                Tags = textBox.Text
            });
            list.ItemsSource = photos.Select(p => new 
            {
                p.Title,
                p.ThumbnailUrl,
                p.WebUrl,
                Command = new InsertCommand(p.Title, p.SmallUrl ?? p.Small320Url, SendEvent)
            });
            statusText.Text = "finished";
        }

        public class InsertCommand : ICommand
        {
            private readonly string url;
            private readonly string title;
            private EventHandler<string[]> handler;
            public InsertCommand(string title, string url, EventHandler<string[]> handler)
            {
                this.title = title;
                this.url = url;
                this.handler = handler;
            }
            public bool CanExecute(object parameter)
            {
                return true;
            }

            public event EventHandler CanExecuteChanged;

            public void Execute(object parameter)
            {
                handler.Invoke(this, new []{title, url});
            }
        }
    }
}
