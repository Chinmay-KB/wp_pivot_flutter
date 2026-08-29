using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.IO.IsolatedStorage;
using System.Text;
using System.Windows;
using System.Windows.Input;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;

namespace ApplicationBarReference
{
    public partial class MainPage : PhoneApplicationPage
    {
        private readonly Stopwatch clock = Stopwatch.StartNew();
        private readonly StringBuilder state = new StringBuilder("t_ms,event,value\n");
        private readonly StringBuilder inputs = new StringBuilder("t_ms,event,id,x,y\n");

        public MainPage()
        {
            InitializeComponent();
            Loaded += (sender, args) =>
            {
                Touch.FrameReported += RecordTouch;
                RecordState("loaded", ApplicationBar.Mode.ToString());
            };
            Unloaded += (sender, args) => { Touch.FrameReported -= RecordTouch; };
            App.SaveEvidence = Save;
        }

        private void RecordState(string eventName, string value)
        {
            state.AppendFormat(CultureInfo.InvariantCulture, "{0:F4},{1},{2}\n",
                clock.Elapsed.TotalMilliseconds, eventName, value);
        }

        private void PreviousClicked(object sender, EventArgs e)
        {
            RecordState("button", "previous");
            StateText.Text = "previous";
        }

        private void NextClicked(object sender, EventArgs e)
        {
            RecordState("button", "next");
            StateText.Text = "next";
        }

        private void SettingsClicked(object sender, EventArgs e)
        {
            RecordState("menu", "settings");
            StateText.Text = "settings";
        }

        private void AboutClicked(object sender, EventArgs e)
        {
            RecordState("menu", "about");
            StateText.Text = "about";
        }

        private void ToggleModeClicked(object sender, RoutedEventArgs e)
        {
            ApplicationBar.Mode = ApplicationBar.Mode == ApplicationBarMode.Default
                ? ApplicationBarMode.Minimized : ApplicationBarMode.Default;
            RecordState("mode", ApplicationBar.Mode.ToString());
            StateText.Text = ApplicationBar.Mode == ApplicationBarMode.Default
                ? "default" : "minimized";
        }

        private void OpenDetailClicked(object sender, RoutedEventArgs e)
        {
            RecordState("navigate", "detail");
            NavigationService.Navigate(new Uri("/DetailPage.xaml", UriKind.Relative));
        }

        private void RecordTouch(object sender, TouchFrameEventArgs args)
        {
            foreach (var point in args.GetTouchPoints(this))
                inputs.AppendFormat(CultureInfo.InvariantCulture, "{0:F4},{1},{2},{3:F4},{4:F4}\n",
                    clock.Elapsed.TotalMilliseconds, point.Action, point.TouchDevice.Id,
                    point.Position.X, point.Position.Y);
        }

        private void Save()
        {
            using (var store = IsolatedStorageFile.GetUserStoreForApplication())
            {
                using (var writer = new StreamWriter(store.CreateFile("state.csv"))) writer.Write(state.ToString());
                using (var writer = new StreamWriter(store.CreateFile("inputs.csv"))) writer.Write(inputs.ToString());
                using (var writer = new StreamWriter(store.CreateFile("platform.txt")))
                {
                    writer.WriteLine("os=" + Environment.OSVersion);
                    writer.WriteLine("control=" + typeof(ApplicationBar).Assembly.FullName);
                    writer.WriteLine("viewport=" + ActualWidth + "x" + ActualHeight);
                    writer.WriteLine("clock_frequency=" + Stopwatch.Frequency);
                    writer.WriteLine("application_bar_mode=" + ApplicationBar.Mode);
                    writer.WriteLine("input_logging_enabled=True");
                }
            }
        }
    }
}
