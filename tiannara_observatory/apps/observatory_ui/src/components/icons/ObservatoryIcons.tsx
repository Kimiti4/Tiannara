import type { SVGProps } from 'react'

type IconProps = SVGProps<SVGSVGElement> & { size?: number }

const B = ({ size = 20, ...p }: IconProps) => <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" {...p} />

export const IconMissionControl = (p: IconProps) => <B {...p}><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></B>
export const IconShield = (p: IconProps) => <B {...p}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></B>
export const IconRuntime = (p: IconProps) => <B {...p}><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></B>
export const IconScience = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></B>
export const IconEngineering = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="3"/><path d="M12 1v6m0 6v6m11-7h-6m-6 0H5"/></B>
export const IconKnowledge = (p: IconProps) => <B {...p}><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></B>
export const IconTheory = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="3"/><path d="M2 12h20M2 12l10-10M2 12l10 10"/></B>
export const IconPlanetary = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></B>
export const IconCivilization = (p: IconProps) => <B {...p}><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></B>
export const IconEvolution = (p: IconProps) => <B {...p}><path d="M12 2a10 10 0 1 0 10 10H12V2z"/><path d="M12 12L2.5 7.5"/></B>
export const IconReplay = (p: IconProps) => <B {...p}><rect x="4" y="4" width="16" height="16" rx="2"/><path d="M4 12h16M12 4v16"/></B>
export const IconSettings = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></B>
export const IconObservationBus = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="10"/><path d="M12 2v20M2 12h20M12 12l8.66-5M12 12l8.66 5M12 12l-8.66-5M12 12l-8.66 5"/><circle cx="12" cy="12" r="3"/></B>
export const IconCertificate = (p: IconProps) => <B {...p}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></B>
export const IconAlert = (p: IconProps) => <B {...p}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></B>
export const IconCheck = (p: IconProps) => <B {...p}><polyline points="20 6 9 17 4 12"/></B>
export const IconInfo = (p: IconProps) => <B {...p}><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></B>
export const IconWarning = (p: IconProps) => <B {...p}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/></B>
