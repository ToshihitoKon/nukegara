import XMonad

--XMonad.Actions
import XMonad.Actions.CycleWS

--XMonad.Layout
import XMonad.Layout.Spacing
import XMonad.Layout.ResizableTile
import XMonad.Layout.Gaps
import XMonad.Layout.Grid
import XMonad.Layout.SimplestFloat
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.BinarySpacePartition

--XMonad.Hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks

--XMonad.Util
import XMonad.Util.Run
import XMonad.Util.EZConfig

--XMonad.Config
import XMonad.Config.Desktop


main = do
    barLeft <- spawnPipe $ "dzen2 -x 0 -w 700 -ta l " ++ dzen_opts
    right <- spawnPipe $ "conky -c ~/.xmonad/conky/conky_config | dzen2 -x 700 -ta r " ++ dzen_opts
    xmonad $ desktopConfig 
                { borderWidth        = 2
                , terminal           = "sakura"
                , modMask            = modm
                , focusedBorderColor = "#f98289"
                , normalBorderColor  = "#ffffff"
                , logHook            = dynamicLogWithPP $ my_dzen_PP barLeft
                , manageHook         = manageDocks <+> manageHook desktopConfig
                , handleEventHook    = docksEventHook <+> handleEventHook desktopConfig
                , layoutHook         = avoidStruts $ myLayout 
                }

                `additionalKeys`
                [ ((modm .|. controlMask, xK_l     ), sendMessage $ ExpandTowards R )
                , ((modm .|. controlMask, xK_h     ), sendMessage $ ShrinkFrom R )
                , ((modm .|. controlMask, xK_j     ), sendMessage $ ExpandTowards D )
                , ((modm .|. controlMask, xK_k     ), sendMessage $ ShrinkFrom D )
                , ((modm                , xK_h     ), prevWS )
                , ((modm                , xK_l     ), nextWS )
                , ((modm .|. shiftMask  , xK_h     ), shiftToPrev )
                , ((modm .|. shiftMask  , xK_l     ), shiftToNext )
                , ((modm                , xK_r     ), sendMessage Rotate )
                , ((modm                , xK_s     ), sendMessage Swap )
                , ((modm                , xK_b     ), sendMessage ToggleStruts )
                , ((modm .|. controlMask, xK_space ), sendMessage ToggleLayout)
                , ((modm .|. controlMask, xK_Return), spawn "transparentwindow")
                , ((0, 0x1008ff11), spawn "pamixer --decrease 2")
                , ((0, 0x1008ff13), spawn "pamixer --increase 2")
                , ((0, 0x1008ff12), spawn "pamixer --toggle-mute")
                , ((0, 0x1008ff03), spawn "xbacklight -dec 10")
                , ((0, 0x1008ff02), spawn "xbacklight -inc 10")
                , ((modm                , xK_c     ), spawn "/home/temama/.xmonad/toggle_composite.sh" )
                , ((modm                , xK_p     ), spawn "rofi -show run" )
                ]

modm = mod1Mask

myLayout = onWorkspace "6" simplestFloat $
           toggleLayouts ( noBorders Full ) $
           gaps [(U,8), (D,8), (L,8), (R,8)] $
           spacing 3 $
           bsp ||| tall ||| grid
           where bsp  = emptyBSP
                 tall = ResizableTall 1 (2/50) (2/3) []
                 grid = Grid

dzen_opts = "-h 14 -fg '#fff' -bg '#a44' -dock -fn 'Source Code Pro:Semibold:size=10'"

my_dzen_PP h = defaultPP { ppCurrent = dzenColor "#0fa" "" . wrap "[" "]"
                         , ppVisible = dzenColor "#0fa" "" . wrap "(" ")"
                         , ppHidden  = dzenColor "#0a1" "" . wrap "" ""
                         , ppUrgent  = dzenColor "#f00" "" . wrap " " " "
                         , ppSep     = " : "
                         , ppLayout  = dzenColor "#fff" ""
                         , ppOutput  = hPutStrLn h
                         }
