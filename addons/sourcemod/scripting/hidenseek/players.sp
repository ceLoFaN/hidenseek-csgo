stock Float:GetPlayerSpeed(iClient)
{
    new Float:faVelocity[3];
    GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", faVelocity);

    new Float:fSpeed;
    fSpeed = SquareRoot(faVelocity[0] * faVelocity[0] + faVelocity[1] * faVelocity[1]);
    fSpeed *= GetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue");

    return fSpeed;
}
