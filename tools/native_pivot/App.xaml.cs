using System;
using System.Windows;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;

namespace PivotReference
{
    public partial class App : Application
    {
        public static Action SaveEvidence;
        public App()
        {
            InitializeComponent();
            var frame = new PhoneApplicationFrame();
            frame.Navigated += (sender, args) => { if (RootVisual != frame) RootVisual = frame; };
            PhoneApplicationService.Current.Closing += (sender, args) => { if (SaveEvidence != null) SaveEvidence(); };
            PhoneApplicationService.Current.Deactivated += (sender, args) => { if (SaveEvidence != null) SaveEvidence(); };
        }
    }
}
