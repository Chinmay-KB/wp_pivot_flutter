using System;
using System.Globalization;
using System.IO;
using System.IO.IsolatedStorage;
using System.Text;
using System.Windows;
using System.Windows.Input;
using Microsoft.Phone.Controls;

namespace ToggleSwitchReference
{
    public partial class MainPage : PhoneApplicationPage
    {
        private readonly System.Diagnostics.Stopwatch clock = System.Diagnostics.Stopwatch.StartNew();
        private readonly StringBuilder states = new StringBuilder("t_ms,id,event,is_checked\n");
        private readonly StringBuilder inputs = new StringBuilder("t_ms,event,id,x,y\n");

        public MainPage()
        {
            InitializeComponent();
            Loaded += (sender, args) => Touch.FrameReported += RecordTouch;
            Unloaded += (sender, args) => Touch.FrameReported -= RecordTouch;
            App.SaveEvidence = Save;
        }

        private void ToggleChecked(object sender, RoutedEventArgs args) { RecordState((FrameworkElement)sender, "checked", true); }
        private void ToggleUnchecked(object sender, RoutedEventArgs args) { RecordState((FrameworkElement)sender, "unchecked", false); }

        private void RecordState(FrameworkElement sender, string action, bool value)
        {
            states.AppendFormat(CultureInfo.InvariantCulture, "{0:F4},{1},{2},{3}\n", clock.Elapsed.TotalMilliseconds, sender.Name, action, value);
        }

        private void RecordTouch(object sender, TouchFrameEventArgs args)
        {
            foreach (var point in args.GetTouchPoints(this))
                inputs.AppendFormat(CultureInfo.InvariantCulture, "{0:F4},{1},{2},{3:F4},{4:F4}\n", clock.Elapsed.TotalMilliseconds, point.Action, point.TouchDevice.Id, point.Position.X, point.Position.Y);
        }

        private void Save()
        {
            using (var store = IsolatedStorageFile.GetUserStoreForApplication())
            {
                using (var writer = new StreamWriter(store.CreateFile("state.csv"))) writer.Write(states.ToString());
                using (var writer = new StreamWriter(store.CreateFile("inputs.csv"))) writer.Write(inputs.ToString());
                using (var writer = new StreamWriter(store.CreateFile("platform.txt")))
                {
                    writer.WriteLine("os=" + Environment.OSVersion);
                    writer.WriteLine("control=" + typeof(Microsoft.Phone.Controls.ToggleSwitch).Assembly.FullName);
                    writer.WriteLine("viewport=" + ActualWidth + "x" + ActualHeight);
                    writer.WriteLine("clock_frequency=" + System.Diagnostics.Stopwatch.Frequency);
                    writer.WriteLine("input_logging_enabled=True");
                }
            }
        }
    }
}
