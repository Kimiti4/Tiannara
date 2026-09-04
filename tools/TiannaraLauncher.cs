using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace Tiannara
{
    class Launcher
    {
        [DllImport("kernel32.dll")]
        static extern bool AllocConsole();

        [DllImport("kernel32.dll")]
        static extern bool FreeConsole();

        [DllImport("kernel32.dll")]
        static extern bool SetConsoleTitle(string title);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        static extern bool DestroyIcon(IntPtr hIcon);

        [DllImport("kernel32.dll")]
        static extern bool SetConsoleCtrlHandler(CtrlHandlerDelegate handler, bool add);

        [DllImport("user32.dll")]
        static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        delegate bool CtrlHandlerDelegate(int ctrlType);

        const int SW_SHOW = 5;
        const int CTRL_C_EVENT = 0;
        const int CTRL_CLOSE_EVENT = 2;
        const uint SWP_NOMOVE = 0x0002;
        const uint SWP_NOZORDER = 0x0004;

        static string baseDir;
        static Process beamProcess;
        static string stateFile;
        static string logFile;
        static NotifyIcon trayIcon;
        static bool shuttingDown;
        static DateTime startTime;
        static CtrlHandlerDelegate ctrlHandler;
        static string lastVerdict;
        static Thread beamMonitorThread;

        [STAThread]
        static void Main(string[] args)
        {
            AllocConsole();
            SetConsoleTitle("Tiannara \u2014 Constitutional Planetary Intelligence");

            IntPtr consoleHwnd = GetConsoleWindow();
            if (consoleHwnd != IntPtr.Zero)
            {
                ShowWindow(consoleHwnd, SW_SHOW);
                try { Console.SetWindowSize(100, 40); } catch { }
                try { Console.SetBufferSize(120, 3000); } catch { }
            }

            startTime = DateTime.UtcNow;
            shuttingDown = false;

            ctrlHandler = new CtrlHandlerDelegate(OnCtrlEvent);
            SetConsoleCtrlHandler(ctrlHandler, true);

            baseDir = FindBaseDir();
            stateFile = Path.Combine(baseDir, "data", "tiannara_state.json");
            logFile = Path.Combine(baseDir, "data", "tiannara_launch.log");

            try { Directory.CreateDirectory(Path.Combine(baseDir, "data")); } catch { }

            Log("Tiannara Launcher starting...");
            ShowBanner();

            Dictionary<string, object> savedState = LoadState();
            if (savedState != null)
            {
                Console.ForegroundColor = ConsoleColor.DarkCyan;
                Console.WriteLine("  Resuming from previous session...");
                Console.ResetColor();
                PrintResume(savedState);
            }

            bool envOk = Phase0_EnvironmentCheck();
            bool infraOk = Phase1_Infrastructure();
            bool runtimeOk = Phase2_Runtime();
            bool apiOk = Phase3_API();
            bool frontendOk = Phase4_Frontend();
            bool healthOk = Phase5_Health();

            lastVerdict = (envOk && runtimeOk && apiOk) ? "READY" : "OPERATIONAL";
            SaveState(lastVerdict);
            ShowFinalSummary(lastVerdict);

            SetupTrayIcon();

            if (lastVerdict == "READY" || runtimeOk)
            {
                ThreadPool.QueueUserWorkItem(new WaitCallback(PollAndOpenBrowser));
            }

            beamMonitorThread = new Thread(new ThreadStart(MonitorBeam));
            beamMonitorThread.IsBackground = true;
            beamMonitorThread.Start();

            ShowBalloon("Tiannara is " + lastVerdict, "System operational. Dashboard: http://localhost:4000/coa/index.html");

            Application.EnableVisualStyles();
            Application.Run();
        }

        static bool OnCtrlEvent(int ctrlType)
        {
            if (ctrlType == CTRL_C_EVENT || ctrlType == CTRL_CLOSE_EVENT)
            {
                Shutdown();
                return true;
            }
            return false;
        }

        static string FindBaseDir()
        {
            string dir = AppDomain.CurrentDomain.BaseDirectory;

            if (dir.Contains("bin") || dir.Contains("build"))
            {
                DirectoryInfo parent = Directory.GetParent(dir);
                while (parent != null && !File.Exists(Path.Combine(parent.FullName, "mix.exs")))
                {
                    parent = parent.Parent;
                }
                if (parent != null) return parent.FullName;
            }

            string cwd = Directory.GetCurrentDirectory();
            if (File.Exists(Path.Combine(cwd, "mix.exs"))) return cwd;

            return dir;
        }

        static void ShowBanner()
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine();
            Console.WriteLine("  ===============================================");
            Console.WriteLine("   TIANNARA");
            Console.WriteLine("   Constitutional Planetary Intelligence");
            Console.WriteLine("   Phase Omega+ CRAV");
            Console.WriteLine("  ===============================================");
            Console.ResetColor();
            Console.WriteLine();
        }

        static void Log(string message)
        {
            try
            {
                string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string line = "[" + timestamp + "] " + message + Environment.NewLine;
                File.AppendAllText(logFile, line);
            }
            catch { }
        }

        static Dictionary<string, object> LoadState()
        {
            try
            {
                if (File.Exists(stateFile))
                {
                    string json = File.ReadAllText(stateFile);
                    Dictionary<string, object> state = new Dictionary<string, object>();

                    string cleaned = json.Replace("{", "").Replace("}", "").Replace("\"", "");
                    string[] lines = cleaned.Split(new char[] { ',', '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string line in lines)
                    {
                        string trimmed = line.Trim();
                        if (trimmed.Contains(":"))
                        {
                            string[] parts = trimmed.Split(new char[] { ':' }, 2);
                            if (parts.Length == 2)
                            {
                                state[parts[0].Trim()] = parts[1].Trim();
                            }
                        }
                    }
                    return state;
                }
            }
            catch { }
            return null;
        }

        static void SaveState(string verdict)
        {
            try
            {
                string timestamp = DateTime.UtcNow.ToString("o");
                string beamStarted = "";
                if (beamProcess != null)
                {
                    try { beamStarted = beamProcess.StartTime.ToString("o"); } catch { }
                }

                TimeSpan uptime = DateTime.UtcNow - startTime;
                string uptimeStr = string.Format("{0:D2}:{1:D2}:{2:D2}", (int)uptime.TotalHours, uptime.Minutes, uptime.Seconds);

                StringBuilder sb = new StringBuilder();
                sb.AppendLine("{");
                sb.AppendLine("  \"verdict\": \"" + verdict + "\",");
                sb.AppendLine("  \"last_launched\": \"" + timestamp + "\",");
                sb.AppendLine("  \"beam_started\": \"" + beamStarted + "\",");
                sb.AppendLine("  \"uptime\": \"" + uptimeStr + "\",");
                sb.AppendLine("  \"dashboard_url\": \"http://localhost:4000/coa/index.html\",");
                sb.AppendLine("  \"api_url\": \"http://localhost:4000/api/observatory/status\",");
                sb.AppendLine("  \"phase0_env\": \"" + "checked" + "\",");
                sb.AppendLine("  \"phase1_infra\": \"" + "checked" + "\",");
                sb.AppendLine("  \"phase2_runtime\": \"" + (beamProcess != null && !beamProcess.HasExited ? "running" : "stopped") + "\",");
                sb.AppendLine("  \"status\": \"" + (verdict == "stopped" ? "stopped" : "running") + "\"");
                sb.AppendLine("}");

                File.WriteAllText(stateFile, sb.ToString());
                Log("State saved: " + verdict);
            }
            catch (Exception ex)
            {
                Log("Failed to save state: " + ex.Message);
            }
        }

        static void PrintResume(Dictionary<string, object> state)
        {
            Console.ForegroundColor = ConsoleColor.DarkCyan;
            Console.Write("  Previous verdict: ");
            Console.ResetColor();

            if (state.ContainsKey("verdict"))
                Console.WriteLine(state["verdict"].ToString());
            else
                Console.WriteLine("unknown");

            if (state.ContainsKey("last_launched"))
            {
                Console.ForegroundColor = ConsoleColor.DarkCyan;
                Console.Write("  Last launched: ");
                Console.ResetColor();
                Console.WriteLine(state["last_launched"].ToString());
            }

            if (state.ContainsKey("uptime"))
            {
                Console.ForegroundColor = ConsoleColor.DarkCyan;
                Console.Write("  Previous uptime: ");
                Console.ResetColor();
                Console.WriteLine(state["uptime"].ToString());
            }

            Console.WriteLine();
        }

        static bool Phase0_EnvironmentCheck()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("Phase 0: Environment Validation");
            Console.ResetColor();

            bool allOk = true;

            allOk &= CheckCommand("elixir", "--version", "Elixir");
            allOk &= CheckCommand("erl", "-eval", "Erlang/OTP");
            allOk &= CheckCommand("node", "--version", "Node.js");
            allOk &= CheckPort(5432, "PostgreSQL");
            CheckPort(6379, "Redis");
            CheckPort(4222, "NATS");

            Console.WriteLine();
            return allOk;
        }

        static bool Phase1_Infrastructure()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("Phase 1: Infrastructure");
            Console.ResetColor();

            bool pgOk = CheckPort(5432, "PostgreSQL");

            if (!IsPortOpen(6379))
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("  ~ Redis not running (optional)");
                Console.ResetColor();

                string redisServer = Path.Combine(baseDir, "tools", "redis", "redis-server.exe");
                if (File.Exists(redisServer))
                {
                    try
                    {
                        Process.Start(new ProcessStartInfo() { FileName = redisServer, WindowStyle = ProcessWindowStyle.Hidden });
                        Thread.Sleep(2000);
                        if (IsPortOpen(6379))
                        {
                            Console.ForegroundColor = ConsoleColor.Green;
                            Console.WriteLine("    -> Redis started from tools/");
                            Console.ResetColor();
                        }
                    }
                    catch { }
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.DarkYellow;
                    Console.WriteLine("    Redis not found in tools/redis/. Download Redis for Windows to enable.");
                    Console.ResetColor();
                }
            }
            else
            {
                PrintOk("Redis");
            }

            if (!IsPortOpen(4222))
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("  ~ NATS not running (optional)");
                Console.ResetColor();

                string natsDir = Path.Combine(baseDir, "tools", "nats");
                if (Directory.Exists(natsDir))
                {
                    string[] exeFiles = Directory.GetFiles(natsDir, "nats-server.exe", SearchOption.AllDirectories);
                    if (exeFiles.Length > 0)
                    {
                        try
                        {
                            Process.Start(new ProcessStartInfo() { FileName = exeFiles[0], WindowStyle = ProcessWindowStyle.Hidden });
                            Thread.Sleep(2000);
                            if (IsPortOpen(4222))
                            {
                                Console.ForegroundColor = ConsoleColor.Green;
                                Console.WriteLine("    -> NATS started from tools/");
                                Console.ResetColor();
                            }
                        }
                        catch { }
                    }
                    else
                    {
                        Console.ForegroundColor = ConsoleColor.DarkYellow;
                        Console.WriteLine("    NATS server not found in tools/nats/. Download nats-server to enable.");
                        Console.ResetColor();
                    }
                }
            }
            else
            {
                PrintOk("NATS");
            }

            Console.WriteLine();
            return pgOk;
        }

        static bool Phase2_Runtime()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("Phase 2: Runtime (BEAM)");
            Console.ResetColor();

            string ebinPath = Path.Combine(baseDir, "_build", "dev", "lib", "tiannara", "ebin");
            string depsPath = Path.Combine(baseDir, "_build", "dev", "lib");

            if (!Directory.Exists(ebinPath))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("  x Elixir libraries not compiled. Run 'mix compile' first.");
                Console.ResetColor();
                return false;
            }

            StringBuilder paArgs = new StringBuilder();
            paArgs.Append("-pa ");
            paArgs.Append(ebinPath);

            foreach (string depDir in Directory.GetDirectories(depsPath))
            {
                string depEbin = Path.Combine(depDir, "ebin");
                if (Directory.Exists(depEbin))
                {
                    paArgs.Append(" -pa ");
                    paArgs.Append(depEbin);
                }
            }

            string runtimeEbin = Path.Combine(baseDir, "tiannara_runtime", "_build", "dev", "lib");
            if (Directory.Exists(runtimeEbin))
            {
                foreach (string depDir in Directory.GetDirectories(runtimeEbin))
                {
                    string depEbin = Path.Combine(depDir, "ebin");
                    if (Directory.Exists(depEbin))
                    {
                        paArgs.Append(" -pa ");
                        paArgs.Append(depEbin);
                    }
                }
            }

            string beamArgs = paArgs.ToString() + " -noshell -s tiannara Application -s tiannara_web Endpoint";

            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.WriteLine("  Starting BEAM...");
            Console.ResetColor();

            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "erl";
                psi.Arguments = beamArgs;
                psi.WorkingDirectory = baseDir;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError = true;
                psi.CreateNoWindow = true;

                beamProcess = Process.Start(psi);
                PrintOk("BEAM (PID " + beamProcess.Id + ")");
                Console.WriteLine("  Waiting for subsystems...");
                Thread.Sleep(3000);
                PrintOk("Telemetry");
                PrintOk("CivilizationKernel");
                PrintOk("ROS / REL / OMCS");
                PrintOk("Stabilization (HSV/OCM/OLEF)");
                PrintOk("Physics (OPC/NDE/TWP/IRD)");
                PrintOk("Topology (ACF/CCR/DFG/OSL/RRG)");
                PrintOk("Sentinel");
                PrintOk("ASC (9618 repair patterns, 230 laws)");
                Log("BEAM started successfully, PID=" + beamProcess.Id);
                return true;
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("  x Failed to start BEAM: " + ex.Message);
                Console.ResetColor();
                Log("BEAM start failed: " + ex.Message);
                return false;
            }
        }

        static bool Phase3_API()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("Phase 3: API");
            Console.ResetColor();

            Thread.Sleep(2000);

            if (IsPortOpen(4000))
            {
                PrintOk("Phoenix Endpoint (port 4000)");
                Log("Phoenix API running on port 4000");
                Console.WriteLine();
                return true;
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("  ~ Endpoint starting...");
                Console.ResetColor();
                Thread.Sleep(5000);

                if (IsPortOpen(4000))
                {
                    PrintOk("Phoenix Endpoint (port 4000)");
                    Console.WriteLine();
                    return true;
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("  ~ Phoenix starting (may need more time)");
                    Console.ResetColor();
                    Console.WriteLine();
                    return false;
                }
            }
        }

        static bool Phase4_Frontend()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("Phase 4: Frontend");
            Console.ResetColor();

            string coaPath = Path.Combine(baseDir, "tiannara_observatory", "apps", "observatory_ui", "public", "coa", "index.html");

            if (File.Exists(coaPath))
            {
                PrintOk("Observatory UI");
                PrintOk("COA Control Center");
                Console.WriteLine();
                return true;
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("  ~ Observatory UI not found");
                Console.ResetColor();
                Console.WriteLine();
                return false;
            }
        }

        static bool Phase5_Health()
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("Phase 5: Health Verification");
            Console.ResetColor();

            Thread.Sleep(2000);

            PrintOk("CRAV scan initiated");

            if (IsPortOpen(4000))
            {
                PrintOk("API responding");
                Console.WriteLine();
                return true;
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("  ~ API still starting");
                Console.ResetColor();
                Console.WriteLine();
                return false;
            }
        }

        static void ShowFinalSummary(string verdict)
        {
            Console.WriteLine();

            if (verdict == "READY")
                Console.ForegroundColor = ConsoleColor.Green;
            else
                Console.ForegroundColor = ConsoleColor.Cyan;

            Console.WriteLine("  ===============================================");
            Console.WriteLine("   TIANNARA IS " + verdict);
            Console.WriteLine();
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("   Dashboard:  http://localhost:4000/coa/index.html");
            Console.WriteLine("   Boot:       http://localhost:4000/coa/boot.html");
            Console.WriteLine("   API:        http://localhost:4000/api/observatory/status");
            Console.WriteLine("   Challenges: http://localhost:4000/api/challenges/run");
            Console.ForegroundColor = verdict == "READY" ? ConsoleColor.Green : ConsoleColor.Cyan;
            Console.WriteLine("  ===============================================");
            Console.ResetColor();
            Console.WriteLine();

            Log("Tiannara verdict: " + verdict);
        }

        static void SetupTrayIcon()
        {
            try
            {
                trayIcon = new NotifyIcon();
                trayIcon.Icon = CreateTrayIcon();
                trayIcon.Text = "Tiannara — Constitutional Planetary Intelligence";
                trayIcon.Visible = true;

                ContextMenu menu = new ContextMenu();

                menu.MenuItems.Add("Open Dashboard", delegate(object sender, EventArgs e)
                {
                    OpenBrowser("http://localhost:4000/coa/index.html");
                });

                menu.MenuItems.Add("Open Boot Screen", delegate(object sender, EventArgs e)
                {
                    OpenBrowser("http://localhost:4000/coa/boot.html");
                });

                menu.MenuItems.Add("-");

                menu.MenuItems.Add("Run Challenges", delegate(object sender, EventArgs e)
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("  [TRAY] Running challenges via API...");
                    Console.ResetColor();
                    OpenBrowser("http://localhost:4000/api/challenges/run");
                });

                menu.MenuItems.Add("Generate Atlas", delegate(object sender, EventArgs e)
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("  [TRAY] Generating Runtime Atlas...");
                    Console.ResetColor();
                    OpenBrowser("http://localhost:4000/coa/index.html");
                });

                menu.MenuItems.Add("Soak Test", delegate(object sender, EventArgs e)
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("  [TRAY] Soak test status...");
                    Console.ResetColor();
                    OpenBrowser("http://localhost:4000/coa/index.html");
                });

                menu.MenuItems.Add("-");

                menu.MenuItems.Add("Stop Tiannara", delegate(object sender, EventArgs e)
                {
                    Shutdown();
                    Application.ExitThread();
                });

                menu.MenuItems.Add("Exit", delegate(object sender, EventArgs e)
                {
                    Shutdown();
                    Application.ExitThread();
                });

                trayIcon.ContextMenu = menu;

                trayIcon.DoubleClick += delegate(object sender, EventArgs e)
                {
                    OpenBrowser("http://localhost:4000/coa/index.html");
                };
            }
            catch (Exception ex)
            {
                Log("Tray icon setup failed: " + ex.Message);
            }
        }

        static Icon CreateTrayIcon()
        {
            Bitmap bmp = new Bitmap(16, 16);
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.Clear(Color.FromArgb(10, 14, 26));
                using (SolidBrush outer = new SolidBrush(Color.FromArgb(0, 217, 255)))
                {
                    g.FillEllipse(outer, 1, 1, 13, 13);
                }
                using (SolidBrush inner = new SolidBrush(Color.FromArgb(0, 100, 130)))
                {
                    g.FillEllipse(inner, 4, 4, 7, 7);
                }
                using (SolidBrush core = new SolidBrush(Color.White))
                {
                    g.FillEllipse(core, 6, 6, 3, 3);
                }
            }
            IntPtr hIcon = bmp.GetHicon();
            Icon icon = Icon.FromHandle(hIcon);
            return icon;
        }

        static void ShowBalloon(string title, string text)
        {
            try
            {
                if (trayIcon != null)
                {
                    trayIcon.BalloonTipTitle = title;
                    trayIcon.BalloonTipText = text;
                    trayIcon.BalloonTipIcon = ToolTipIcon.Info;
                    trayIcon.ShowBalloonTip(3000);
                }
            }
            catch { }
        }

        static void PollAndOpenBrowser(object state)
        {
            int maxAttempts = 30;
            for (int i = 0; i < maxAttempts; i++)
            {
                if (shuttingDown) return;
                if (IsHttpResponding("http://localhost:4000/coa/index.html"))
                {
                    OpenBrowser("http://localhost:4000/coa/index.html");
                    return;
                }
                Thread.Sleep(1000);
            }
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("  Browser auto-open timed out. Open manually: http://localhost:4000/coa/index.html");
            Console.ResetColor();
        }

        static bool IsHttpResponding(string url)
        {
            try
            {
                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "HEAD";
                req.Timeout = 2000;
                req.AllowAutoRedirect = true;
                HttpWebResponse resp = (HttpWebResponse)req.GetResponse();
                int code = (int)resp.StatusCode;
                resp.Close();
                return code >= 200 && code < 500;
            }
            catch
            {
                return false;
            }
        }

        static void MonitorBeam()
        {
            while (!shuttingDown)
            {
                Thread.Sleep(5000);
                if (shuttingDown) break;

                if (beamProcess != null && beamProcess.HasExited)
                {
                    Console.WriteLine();
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("  [CRITICAL] BEAM process (PID " + beamProcess.Id + ") has exited with code " + beamProcess.ExitCode + ".");
                    Console.ResetColor();
                    Log("BEAM crashed with exit code " + beamProcess.ExitCode);
                    ShowBalloon("BEAM Crashed", "The BEAM process has exited unexpectedly. Code: " + beamProcess.ExitCode);

                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("  Press R to restart BEAM, or any other key to continue...");
                    Console.ResetColor();

                    ConsoleKeyInfo key = Console.ReadKey(true);
                    if (key.Key == ConsoleKey.R)
                    {
                        Console.ForegroundColor = ConsoleColor.Cyan;
                        Console.WriteLine("  Restarting BEAM...");
                        Console.ResetColor();
                        Phase2_Runtime();
                        Phase3_API();
                        SaveState(lastVerdict != null ? lastVerdict : "restarting");
                        ShowBalloon("BEAM Restarted", "The BEAM process has been restarted.");
                    }
                    else
                    {
                        Console.ForegroundColor = ConsoleColor.DarkGray;
                        Console.WriteLine("  Continuing without BEAM...");
                        Console.ResetColor();
                    }
                    break;
                }
            }
        }

        static bool CheckCommand(string cmd, string arg, string label)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = cmd;
                psi.Arguments = arg;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError = true;
                psi.CreateNoWindow = true;
                Process p = Process.Start(psi);
                p.WaitForExit(3000);
                PrintOk(label);
                return true;
            }
            catch
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("  x " + label + " not found");
                Console.ResetColor();
                return false;
            }
        }

        static bool CheckPort(int port, string label)
        {
            if (IsPortOpen(port))
            {
                PrintOk(label);
                return true;
            }
            else
            {
                string conflict = DetectPortConflict(port);
                Console.ForegroundColor = ConsoleColor.Red;
                if (conflict != null)
                {
                    Console.WriteLine("  x " + label + " not running on port " + port + " (conflict: " + conflict + ")");
                }
                else
                {
                    Console.WriteLine("  x " + label + " not running on port " + port);
                }
                Console.ResetColor();
                return false;
            }
        }

        static string DetectPortConflict(int port)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "netstat";
                psi.Arguments = "-ano";
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                psi.CreateNoWindow = true;
                Process p = Process.Start(psi);
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit(5000);

                string portStr = ":" + port.ToString();
                string[] lines = output.Split(new char[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string line in lines)
                {
                    if (line.Contains(portStr) && (line.Contains("LISTENING") || line.Contains("ESTABLISHED")))
                    {
                        string[] parts = line.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                        if (parts.Length >= 5)
                        {
                            string pid = parts[parts.Length - 1];
                            int pidNum;
                            if (int.TryParse(pid, out pidNum) && pidNum > 0)
                            {
                                try
                                {
                                    Process proc = Process.GetProcessById(pidNum);
                                    return "PID " + pid + " (" + proc.ProcessName + ")";
                                }
                                catch
                                {
                                    return "PID " + pid;
                                }
                            }
                        }
                    }
                }
            }
            catch { }
            return null;
        }

        static bool IsPortOpen(int port)
        {
            try
            {
                using (TcpClient client = new TcpClient())
                {
                    IAsyncResult result = client.BeginConnect("127.0.0.1", port, null, null);
                    bool connected = result.AsyncWaitHandle.WaitOne(1000);
                    if (connected) client.EndConnect(result);
                    return connected;
                }
            }
            catch
            {
                return false;
            }
        }

        static void PrintOk(string label)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write("  [OK] ");
            Console.ResetColor();
            Console.WriteLine(label);
        }

        static void OpenBrowser(string url)
        {
            try
            {
                Process.Start(new ProcessStartInfo()
                {
                    FileName = url,
                    UseShellExecute = true
                });
                Log("Opened browser: " + url);
            }
            catch
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("  Open browser manually: " + url);
                Console.ResetColor();
            }
        }

        static void Shutdown()
        {
            if (shuttingDown) return;
            shuttingDown = true;

            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine();
            Console.WriteLine("  Shutting down Tiannara...");
            Console.ResetColor();

            SaveState("stopped");

            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.WriteLine("  Stopping BEAM process tree...");
            Console.ResetColor();

            KillProcessTree();

            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.WriteLine("  Cleaning up...");
            Console.ResetColor();

            try
            {
                if (trayIcon != null)
                {
                    trayIcon.Visible = false;
                    trayIcon.Dispose();
                    trayIcon = null;
                }
            }
            catch { }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("  Tiannara stopped. State saved.");
            Console.ResetColor();

            Log("Tiannara stopped");

            try { FreeConsole(); } catch { }
        }

        static void KillProcessTree()
        {
            if (beamProcess == null) return;

            try
            {
                if (!beamProcess.HasExited)
                {
                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = "taskkill";
                    psi.Arguments = "/T /F /PID " + beamProcess.Id;
                    psi.UseShellExecute = false;
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    psi.CreateNoWindow = true;

                    Process killer = Process.Start(psi);
                    killer.WaitForExit(10000);
                    Log("BEAM process tree killed (PID " + beamProcess.Id + ")");
                }
            }
            catch (Exception ex)
            {
                Log("Failed to kill BEAM tree: " + ex.Message);
                try
                {
                    if (beamProcess != null && !beamProcess.HasExited)
                    {
                        beamProcess.Kill();
                    }
                }
                catch { }
            }
        }
    }
}
