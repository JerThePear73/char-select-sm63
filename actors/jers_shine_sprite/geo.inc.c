#include "src/game/envfx_snow.h"

const GeoLayout jers_shine_sprite_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_SHADOW(0, 155, 100),
		GEO_OPEN_NODE(),
			GEO_SCALE(LAYER_FORCE, 16384),
			GEO_OPEN_NODE(),
				GEO_DISPLAY_LIST(LAYER_OPAQUE, jers_shine_sprite_Shine_Sprite_DL_mesh_layer_1),
				GEO_DISPLAY_LIST(LAYER_ALPHA, jers_shine_sprite_Shine_Sprite_DL_mesh_layer_4),
			GEO_CLOSE_NODE(),
		GEO_CLOSE_NODE(),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
