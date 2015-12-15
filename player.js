function random_color_string() {
    var color_range = 0xFFFFFF >> 2;
    return "#" + (Math.floor(Math.random() * color_range)
        + color_range * 3).toString(16);
}

/*
 *       ::::::::  :::            :::      ::::::::   ::::::::
 *     :+:    :+: :+:          :+: :+:   :+:    :+: :+:    :+:
 *    +:+        +:+         +:+   +:+  +:+        +:+
 *   +#+        +#+        +#++:++#++: +#++:++#++ +#++:++#++
 *  +#+        +#+        +#+     +#+        +#+        +#+
 * #+#    #+# #+#        #+#     #+# #+#    #+# #+#    #+#
 * ########  ########## ###     ###  ########   ########
 */
Player = function(socket, color, name) {
    this.socket = socket;
    this.color = color || random_color_string();
    this.name = name || 'Generic Name (aka Bob, aka Robert)';
};

/*
 *       :::::::::  :::::::::   :::::::: ::::::::::: ::::::::
 *      :+:    :+: :+:    :+: :+:    :+:    :+:    :+:    :+:
 *     +:+    +:+ +:+    +:+ +:+    +:+    +:+    +:+    +:+
 *    +#++:++#+  +#++:++#:  +#+    +:+    +#+    +#+    +:+
 *   +#+        +#+    +#+ +#+    +#+    +#+    +#+    +#+
 *  #+#        #+#    #+# #+#    #+#    #+#    #+#    #+#
 * ###        ###    ###  ########     ###     ########
 */
Player.prototype = {
    position: [0, 0], /* x/y coordinates */
    orientation: 0, /* radians */
}

/*
 *       :::::::::: :::    ::: :::::::::   ::::::::  ::::::::: :::::::::::
 *      :+:        :+:    :+: :+:    :+: :+:    :+: :+:    :+:    :+:
 *     +:+         +:+  +:+  +:+    +:+ +:+    +:+ +:+    +:+    +:+
 *    +#++:++#     +#++:+   +#++:++#+  +#+    +:+ +#++:++#:     +#+
 *   +#+         +#+  +#+  +#+        +#+    +#+ +#+    +#+    +#+
 *  #+#        #+#    #+# #+#        #+#    #+# #+#    #+#    #+#
 * ########## ###    ### ###         ########  ###    ###    ###
 */
if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports)
        exports = module.exports = Player;
    exports.Player = Player;
}
