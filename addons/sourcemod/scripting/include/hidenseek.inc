#if defined _hidenseek_included_
  #endinput
#endif
#define _hidenseek_included_

public SharedPlugin __pl_hidenseek = 
{
	name = "hidenseek",
	file = "hidenseek.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0
#endif
};

/**
 * Called when CT freeze countdown ended.
 */
forward void HNS_OnCountdownEnd();

/*#if !defined REQUIRE_PLUGIN
public __pl_hidenseek_SetNTVOptional()
{
	MarkNativeAsOptional("");
}
#endif*/