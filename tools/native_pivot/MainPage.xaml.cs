using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.IO.IsolatedStorage;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using Microsoft.Phone.Controls;

namespace PivotReference
{
    public partial class MainPage : PhoneApplicationPage
    {
        private readonly Stopwatch clock = Stopwatch.StartNew();
        private readonly StringBuilder trajectory = new StringBuilder("t_ms,item,content_x,content_y,header_x,header_y,header_width,header_height,selected\n");
        private readonly StringBuilder inputs = new StringBuilder("t_ms,event,id,x,y\n");
        private readonly List<FrameworkElement> contents = new List<FrameworkElement>();
        private readonly string[] names = { "first", "second", "third", "fourth" };
        private int recordedFrames;
#if NO_TRAJECTORY
        private const bool trajectoryEnabled = false;
#else
        private const bool trajectoryEnabled = true;
#endif

        public MainPage()
        {
            InitializeComponent();
            Color[] colors = { Color.FromArgb(255, 27, 161, 226), Color.FromArgb(255, 96, 169, 23),
                               Color.FromArgb(255, 240, 150, 9), Color.FromArgb(255, 162, 0, 255) };
            for (int i = 0; i < names.Length; i++)
            {
                var panel = new StackPanel { Margin = new Thickness(12, 0, 12, 0) };
                panel.Children.Add(new Rectangle { Height = 6, Fill = new SolidColorBrush(colors[i]) });
                panel.Children.Add(new TextBlock { Text = names[i] + " page", FontSize = 32,
                    Margin = new Thickness(0, 24, 0, 0), Foreground = new SolidColorBrush(Colors.White) });
                panel.Children.Add(new TextBlock { Text = "Swipe to explore", FontSize = 24,
                    Margin = new Thickness(0, 12, 0, 0), Foreground = new SolidColorBrush(Color.FromArgb(255, 166, 166, 166)) });
                panel.Children.Add(new Rectangle { Width = 64, Height = 64, Margin = new Thickness(0, 32, 0, 0),
                    HorizontalAlignment = HorizontalAlignment.Left, Fill = new SolidColorBrush(colors[i]) });
                NativePivot.Items.Add(new PivotItem { Header = names[i], Content = panel });
                contents.Add(panel);
            }
            Loaded += (sender, args) => {
                if (trajectoryEnabled) CompositionTarget.Rendering += RecordFrame;
                Touch.FrameReported += RecordTouch;
            };
            Unloaded += (sender, args) => {
                CompositionTarget.Rendering -= RecordFrame;
                Touch.FrameReported -= RecordTouch;
            };
            NativePivot.SelectionChanged += (sender, args) => inputs.AppendFormat(CultureInfo.InvariantCulture,
                "{0:F4},selection,{1},,\n", clock.Elapsed.TotalMilliseconds, NativePivot.SelectedIndex);
            App.SaveEvidence = Save;
        }

        private IEnumerable<TextBlock> TextElements(DependencyObject root)
        {
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(root); i++)
            {
                var child = VisualTreeHelper.GetChild(root, i);
                var text = child as TextBlock;
                if (text != null) yield return text;
                foreach (var nested in TextElements(child)) yield return nested;
            }
        }

        private Point Position(FrameworkElement element)
        {
            try { return element.TransformToVisual(this).Transform(new Point(0, 0)); }
            catch (ArgumentException) { return new Point(double.NaN, double.NaN); }
        }

        private void RecordFrame(object sender, EventArgs args)
        {
            if (recordedFrames++ >= 18000) return; // Bounded five minutes at 60 fps.
            var headers = new Dictionary<string, TextBlock>();
            foreach (var text in TextElements(NativePivot))
                if (Array.IndexOf(names, text.Text) >= 0 && !headers.ContainsKey(text.Text)) headers.Add(text.Text, text);
            double time = clock.Elapsed.TotalMilliseconds;
            for (int i = 0; i < contents.Count; i++)
            {
                Point content = Position(contents[i]);
                TextBlock header;
                bool found = headers.TryGetValue(names[i], out header);
                Point hp = found ? Position(header) : new Point(double.NaN, double.NaN);
                trajectory.AppendFormat(CultureInfo.InvariantCulture,
                    "{0:F4},{1},{2:F4},{3:F4},{4:F4},{5:F4},{6:F4},{7:F4},{8}\n",
                    time, i, content.X, content.Y, hp.X, hp.Y,
                    found ? header.ActualWidth : double.NaN,
                    found ? header.ActualHeight : double.NaN, NativePivot.SelectedIndex);
            }
        }

        private void RecordTouch(object sender, TouchFrameEventArgs args)
        {
            foreach (var point in args.GetTouchPoints(this))
                inputs.AppendFormat(CultureInfo.InvariantCulture, "{0:F4},{1},{2},{3:F4},{4:F4}\n",
                    clock.Elapsed.TotalMilliseconds, point.Action, point.TouchDevice.Id, point.Position.X, point.Position.Y);
        }

        private void Save()
        {
            using (var store = IsolatedStorageFile.GetUserStoreForApplication())
            {
                using (var writer = new StreamWriter(store.CreateFile("trajectory.csv"))) writer.Write(trajectory.ToString());
                using (var writer = new StreamWriter(store.CreateFile("inputs.csv"))) writer.Write(inputs.ToString());
                using (var writer = new StreamWriter(store.CreateFile("styles.txt")))
                {
                    // Read at shutdown, outside the measured interaction.
                    foreach (var text in TextElements(NativePivot))
                    {
                        writer.WriteLine("text=" + text.Text);
                        writer.WriteLine("font_family=" + text.FontFamily.Source);
                        writer.WriteLine("font_size=" + text.FontSize.ToString(CultureInfo.InvariantCulture));
                        writer.WriteLine("font_weight=" + text.FontWeight);
                        var brush = text.Foreground as SolidColorBrush;
                        writer.WriteLine("foreground=" + (brush == null ? "non-solid" : brush.Color.ToString()));
                        writer.WriteLine("size=" + text.ActualWidth.ToString(CultureInfo.InvariantCulture) + "," + text.ActualHeight.ToString(CultureInfo.InvariantCulture));
                        writer.WriteLine();
                    }
                }
                using (var writer = new StreamWriter(store.CreateFile("platform.txt")))
                {
                    writer.WriteLine("os=" + Environment.OSVersion);
                    writer.WriteLine("control=" + typeof(Pivot).Assembly.FullName);
                    writer.WriteLine("viewport=" + ActualWidth + "x" + ActualHeight);
                    writer.WriteLine("clock_frequency=" + Stopwatch.Frequency);
                    writer.WriteLine("render_callbacks=" + recordedFrames);
                    writer.WriteLine("trajectory_enabled=" + trajectoryEnabled);
                    writer.WriteLine("input_logging_enabled=True");
                }
            }
        }
    }
}
