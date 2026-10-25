-- ReplicatedStorage > Shared > AnimationsData (ModuleScript)
-- Реестр анимаций. Вставь свои Asset ID после публикации клипов
-- (Avatar tab > Animation Editor > Publish, ID копируется из ссылки).

return {
	CrouchIdle = { id = 0, loop = true,  priority = Enum.AnimationPriority.Action },
	CrouchWalk = { id = 0, loop = true,  priority = Enum.AnimationPriority.Action },
	ProneIdle  = { id = 0, loop = true,  priority = Enum.AnimationPriority.Action },
	ProneCrawl = { id = 0, loop = true,  priority = Enum.AnimationPriority.Action },
	Slide      = { id = 0, loop = false, priority = Enum.AnimationPriority.Action },
	TacticalSprint = { id = 0, loop = true,  priority = Enum.AnimationPriority.Action },
	Mantle     = { id = 0, loop = false, priority = Enum.AnimationPriority.Action },
	Swim       = { id = 0, loop = true,  priority = Enum.AnimationPriority.Action },
}
