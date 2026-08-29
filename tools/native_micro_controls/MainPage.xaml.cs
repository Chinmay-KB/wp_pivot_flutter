using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.IO.IsolatedStorage;
using System.Text;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using Microsoft.Phone.Controls;

namespace MicroControlsReference
{
    public partial class MainPage : PhoneApplicationPage
    {
        private readonly Stopwatch clock = Stopwatch.StartNew();
        private readonly StringBuilder states = new StringBuilder(
            "t_ms,event,slider_value,slider_x,slider_y,slider_width,slider_height," +
            "determinate_value,determinate_x,determinate_y,determinate_width,determinate_height," +
            "indeterminate_value,indeterminate_state,indeterminate_x,indeterminate_y,indeterminate_width,indeterminate_height," +
            "tilt_projection_present,tilt_rotation_x,tilt_rotation_y,tilt_global_offset_z,tilt_x,tilt_y,tilt_width,tilt_height\n");
        private readonly StringBuilder inputs = new StringBuilder("t_ms,event,id,x,y\n");

        public MainPage()
        {
            InitializeComponent();
            Loaded += PageLoaded;
            Unloaded += PageUnloaded;
            ValueSlider.ValueChanged += SliderValueChanged;
            App.SaveEvidence = Save;
        }

        private void PageLoaded(object sender, RoutedEventArgs args)
        {
            Touch.FrameReported += RecordTouch;
            CompositionTarget.Rendering += RecordRendering;
            RecordState("loaded");
        }

        private void PageUnloaded(object sender, RoutedEventArgs args)
        {
            Touch.FrameReported -= RecordTouch;
            CompositionTarget.Rendering -= RecordRendering;
        }

        private void SliderValueChanged(object sender, RoutedPropertyChangedEventArgs<double> args)
        {
            RecordState("slider_value_changed");
        }

        private void RecordRendering(object sender, EventArgs args)
        {
            RecordState("render");
        }

        private void RecordState(string eventName)
        {
            // Toolkit TiltEffect projects the first visual child of a tiltable
            // control, not the Button itself. Observe that exact target.
            var tiltTarget = VisualTreeHelper.GetChildrenCount(TiltButton) == 0
                ? null
                : VisualTreeHelper.GetChild(TiltButton, 0) as FrameworkElement;
            var projection = tiltTarget == null ? null : tiltTarget.Projection as PlaneProjection;
            var rotationX = projection == null ? 0.0 : projection.RotationX;
            var rotationY = projection == null ? 0.0 : projection.RotationY;
            var globalOffsetZ = projection == null ? 0.0 : projection.GlobalOffsetZ;
            var sliderOrigin = ValueSlider.TransformToVisual(this).Transform(new Point(0, 0));
            var determinateOrigin = DeterminateProgress.TransformToVisual(this).Transform(new Point(0, 0));
            var indeterminateOrigin = IndeterminateProgress.TransformToVisual(this).Transform(new Point(0, 0));
            var tiltOrigin = tiltTarget == null
                ? TiltButton.TransformToVisual(this).Transform(new Point(0, 0))
                : tiltTarget.TransformToVisual(this).Transform(new Point(0, 0));
            states.AppendFormat(
                CultureInfo.InvariantCulture,
                "{0:F4},{1},{2:F4},{3:F4},{4:F4},{5:F4},{6:F4}," +
                "{7:F4},{8:F4},{9:F4},{10:F4},{11:F4}," +
                "{12:F4},{13},{14:F4},{15:F4},{16:F4},{17:F4}," +
                "{18},{19:F4},{20:F4},{21:F4},{22:F4},{23:F4},{24:F4},{25:F4}\n",
                clock.Elapsed.TotalMilliseconds,
                eventName,
                ValueSlider.Value,
                sliderOrigin.X,
                sliderOrigin.Y,
                ValueSlider.ActualWidth,
                ValueSlider.ActualHeight,
                DeterminateProgress.Value,
                determinateOrigin.X,
                determinateOrigin.Y,
                DeterminateProgress.ActualWidth,
                DeterminateProgress.ActualHeight,
                IndeterminateProgress.Value,
                IndeterminateProgress.IsIndeterminate,
                indeterminateOrigin.X,
                indeterminateOrigin.Y,
                IndeterminateProgress.ActualWidth,
                IndeterminateProgress.ActualHeight,
                projection != null,
                rotationX,
                rotationY,
                globalOffsetZ,
                tiltOrigin.X,
                tiltOrigin.Y,
                tiltTarget == null ? TiltButton.ActualWidth : tiltTarget.ActualWidth,
                tiltTarget == null ? TiltButton.ActualHeight : tiltTarget.ActualHeight);
        }

        private void RecordTouch(object sender, TouchFrameEventArgs args)
        {
            foreach (var point in args.GetTouchPoints(this))
            {
                inputs.AppendFormat(
                    CultureInfo.InvariantCulture,
                    "{0:F4},{1},{2},{3:F4},{4:F4}\n",
                    clock.Elapsed.TotalMilliseconds,
                    point.Action,
                    point.TouchDevice.Id,
                    point.Position.X,
                    point.Position.Y);
            }
        }

        protected override void OnBackKeyPress(CancelEventArgs e)
        {
            RecordState("back");
            Save();
            base.OnBackKeyPress(e);
        }

        private void Save()
        {
            using (var store = IsolatedStorageFile.GetUserStoreForApplication())
            {
                using (var writer = new StreamWriter(store.CreateFile("state.csv")))
                    writer.Write(states.ToString());
                using (var writer = new StreamWriter(store.CreateFile("inputs.csv")))
                    writer.Write(inputs.ToString());
                using (var writer = new StreamWriter(store.CreateFile("platform.txt")))
                {
                    writer.WriteLine("os=" + Environment.OSVersion);
                    writer.WriteLine("slider_control=" + typeof(System.Windows.Controls.Slider).Assembly.FullName);
                    writer.WriteLine("progress_control=" + typeof(System.Windows.Controls.ProgressBar).Assembly.FullName);
                    writer.WriteLine("tilt_effect=" + typeof(Microsoft.Phone.Controls.TiltEffect).Assembly.FullName);
                    writer.WriteLine("viewport=" + ActualWidth + "x" + ActualHeight);
                    writer.WriteLine("clock_frequency=" + Stopwatch.Frequency);
                    writer.WriteLine("render_logging_enabled=True");
                    writer.WriteLine("input_logging_enabled=True");
                }
            }
        }
    }
}
