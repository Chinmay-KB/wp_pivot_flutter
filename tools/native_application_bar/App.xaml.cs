using System;
using System.Windows;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;

namespace ApplicationBarReference
{
    public partial class App : Application
    {
        public static Action SaveEvidence;
        public App()
        {
            InitializeComponent();
            // TransitionFrame is required for Toolkit NavigationIn/Out transitions.
            // Plain PhoneApplicationFrame evidence remains in native-nav-01.
            var frame = new TransitionFrame();
            frame.Navigated += (sender, args) => { if (RootVisual != frame) RootVisual = frame; };
            PhoneApplicationService.Current.Closing += (sender, args) => { if (SaveEvidence != null) SaveEvidence(); };
            PhoneApplicationService.Current.Deactivated += (sender, args) => { if (SaveEvidence != null) SaveEvidence(); };
        }
    }
}
