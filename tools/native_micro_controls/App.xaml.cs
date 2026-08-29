using System;
using System.Windows;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;

namespace MicroControlsReference
{
    public partial class App : Application
    {
        public static Action SaveEvidence;

        public App()
        {
            InitializeComponent();
            var frame = new PhoneApplicationFrame();
            frame.Navigated += (sender, args) =>
            {
                if (RootVisual != frame) RootVisual = frame;
            };
            PhoneApplicationService.Current.Closing += (sender, args) => Save();
            PhoneApplicationService.Current.Deactivated += (sender, args) => Save();
        }

        private static void Save()
        {
            if (SaveEvidence != null) SaveEvidence();
        }
    }
}

